#include <errno.h>
#include <fcntl.h>
#include <sys/file.h>
#include <unistd.h>

#include <glib/gstdio.h>

#include "my_application.h"

// TD-7 单实例保护：引擎启动前对数据目录加 OS 级文件锁（flock）。
//
// 不能用 dart:io File.lock：本平台（ARM64 社区引擎构建）strace 实锤
// dart:io 线程池存在 fd 生命周期错乱——某工作线程 close 了一个自己从未
// open 的 fd 号，恰好是「编号被复用」的锁 fd，锁随进程存活期间静默丢失
//（2026-09-03 三实例并发清数据事故根因）。原生 fd 由 main() 持有整个
// 进程生命周期（有意不 close），进程退出（含 SIGKILL）由内核自动释放，
// 无残留锁。
//
// 数据目录与 Dart 侧 getApplicationDocumentsDirectory()（XDG DOCUMENTS）
// 保持一致；test-mode（--test-mode/--ui-test）用独立目录 hopp_test，
// 自动化实例与用户实例互不干扰。
static gboolean is_test_mode(int argc, char** argv) {
  for (int i = 1; i < argc; ++i) {
    if (g_strcmp0(argv[i], "--test-mode") == 0 ||
        g_strcmp0(argv[i], "--ui-test") == 0) {
      return TRUE;
    }
  }
  return FALSE;
}

static gboolean prefer_chinese() {
  const char* lc = g_getenv("LC_ALL");
  if (lc == nullptr || *lc == '\0') lc = g_getenv("LC_MESSAGES");
  if (lc == nullptr || *lc == '\0') lc = g_getenv("LANG");
  return lc != nullptr && g_str_has_prefix(lc, "zh");
}

static void show_already_running_dialog() {
  gtk_init(nullptr, nullptr);
  const gboolean zh = prefer_chinese();
  GtkWidget* dialog = gtk_message_dialog_new(
      nullptr, GTK_DIALOG_MODAL, GTK_MESSAGE_WARNING, GTK_BUTTONS_NONE, "%s",
      zh ? "Hopp 已在运行" : "Hopp Is Already Running");
  gtk_message_dialog_format_secondary_text(
      GTK_MESSAGE_DIALOG(dialog), "%s",
      zh ? "检测到另一个 Hopp 实例正在运行。为保护本地数据，同一时间只允许运行一个实例。\n\n请使用已运行的实例，或先关闭它再重新启动。"
         : "Another Hopp instance is already running. To protect your local data, only one instance can run at a time.\n\nPlease use the running instance, or close it first and relaunch.");
  gtk_window_set_title(GTK_WINDOW(dialog), "Hopp");
  gtk_window_set_position(GTK_WINDOW(dialog), GTK_WIN_POS_CENTER);
  gtk_dialog_add_button(GTK_DIALOG(dialog), zh ? "退出" : "Quit",
                        GTK_RESPONSE_OK);
  gtk_dialog_run(GTK_DIALOG(dialog));
  gtk_widget_destroy(dialog);
}

// 返回 TRUE = 拿到锁（或异常时 fail-open 放行）；FALSE = 已有实例持有。
static gboolean acquire_instance_lock(int argc, char** argv) {
  const char* docs = g_get_user_special_dir(G_USER_DIRECTORY_DOCUMENTS);
  if (docs == nullptr) {
    docs = g_get_home_dir();
  }
  g_autofree gchar* dir =
      g_build_filename(docs, is_test_mode(argc, argv) ? "hopp_test" : "hopp",
                       nullptr);
  if (g_mkdir_with_parents(dir, 0755) != 0) {
    g_warning("[single-instance] mkdir failed: %s — fail-open", dir);
    return TRUE;
  }
  g_autofree gchar* lock_path = g_build_filename(dir, ".hopp.lock", nullptr);
  const int fd = open(lock_path, O_RDWR | O_CREAT, 0644);
  if (fd < 0) {
    g_warning("[single-instance] open %s failed: %s — fail-open", lock_path,
              g_strerror(errno));
    return TRUE;
  }
  if (flock(fd, LOCK_EX | LOCK_NB) != 0) {
    if (errno == EWOULDBLOCK) {
      g_message("[single-instance] another instance holds %s", lock_path);
      close(fd);
      return FALSE;
    }
    g_warning("[single-instance] flock %s failed: %s — fail-open", lock_path,
              g_strerror(errno));
    close(fd);
    return TRUE;
  }
  // 有意不 close：fd 泄漏至进程结束，锁由内核在进程退出时释放
  g_message("[single-instance] lock acquired: %s (fd %d)", lock_path, fd);
  return TRUE;
}

int main(int argc, char** argv) {
  if (!acquire_instance_lock(argc, argv)) {
    show_already_running_dialog();
    return 0;
  }
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
