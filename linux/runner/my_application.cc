#include "my_application.h"

#include <unistd.h>

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#include <X11/Xatom.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// 设置窗口图标。
// Deepin 的 GTK3 补丁会使 gtk_window_set_icon 不写入 _NET_WM_ICON，
// 任务栏/Dock 只能显示占位 X 图标；因此在 X11 下手动补写该属性。
// 图标由 CMake 安装到 bundle 的 data/logo.svg.png，按可执行文件位置解析。
static void set_window_icon(GtkWindow* window, const gchar* exe_dir) {
  gchar* icon_path = g_build_filename(exe_dir, "data", "logo.svg.png", nullptr);
  GError* error = nullptr;
  GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(icon_path, &error);
  g_free(icon_path);
  if (pixbuf == nullptr) {
    g_warning("Failed to load window icon: %s",
              error != nullptr ? error->message : "unknown");
    g_clear_error(&error);
    return;
  }

  // 统一缩到 128px，_NET_WM_ICON 数据更小，Dock 实际展示尺寸也足够。
  const gint size = 128;
  GdkPixbuf* scaled = gdk_pixbuf_scale_simple(
      pixbuf, size, size, GDK_INTERP_BILINEAR);
  g_object_unref(pixbuf);
  if (scaled == nullptr) {
    return;
  }

  gtk_window_set_icon(window, scaled);  // Wayland/GTK 侧

#ifdef GDK_WINDOWING_X11
  if (GDK_IS_X11_SCREEN(gtk_window_get_screen(window))) {
    // 需要 realize 之后才有 XID；realize 不影响后续 show。
    if (!gtk_widget_get_realized(GTK_WIDGET(window))) {
      gtk_widget_realize(GTK_WIDGET(window));
    }
    GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
    if (gdk_window != nullptr) {
      const guchar* src = gdk_pixbuf_get_pixels(scaled);
      const gint channels = gdk_pixbuf_get_n_channels(scaled);
      const gint stride = gdk_pixbuf_get_rowstride(scaled);
      g_autofree gulong* icon = g_new(gulong, 2 + size * size);
      icon[0] = size;
      icon[1] = size;
      for (gint y = 0; y < size; y++) {
        for (gint x = 0; x < size; x++) {
          const guchar* p = src + y * stride + x * channels;
          const guchar r = p[0];
          const guchar g = p[1];
          const guchar b = p[2];
          const guchar a = channels == 4 ? p[3] : 255;
          icon[2 + y * size + x] =
              ((gulong)a << 24) | ((gulong)r << 16) | ((gulong)g << 8) | b;
        }
      }
      Display* display = gdk_x11_display_get_xdisplay(
          gtk_widget_get_display(GTK_WIDGET(window)));
      const Atom atom = XInternAtom(display, "_NET_WM_ICON", False);
      XChangeProperty(display, GDK_WINDOW_XID(gdk_window), atom, XA_CARDINAL,
                      32, PropModeReplace,
                      reinterpret_cast<const unsigned char*>(icon),
                      2 + size * size);
    }
  }
#endif

  g_object_unref(scaled);
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "hopp");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "hopp");
  }

  // 解析可执行文件所在目录，用于定位 bundle 内的窗口图标。
  gchar exe_path[4096];
  const ssize_t exe_len = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
  gchar* exe_dir = nullptr;
  if (exe_len > 0) {
    exe_path[exe_len] = '\0';
    exe_dir = g_path_get_dirname(exe_path);
  }
  if (exe_dir != nullptr) {
    set_window_icon(GTK_WINDOW(window), exe_dir);
    g_free(exe_dir);
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
