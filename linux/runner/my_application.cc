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

// ---- 自定义标题栏（F5.8）----
// Deepin 的 GTK3 补丁重写了 GtkHeaderBar 的尺寸与绘制：实测纯 GTK3 探针应用
// 的 headerbar 也被锁在 ~60px，按钮是 PNG 背景小图标，且 headerbar 子元素
// （按钮/标题）完全不受 CSS 控制（min-height/font-size 均无效，仅 headerbar
// 节点自身的背景/前景色可经 CSS 覆盖）。因此改用普通 GtkBox 作为 titlebar
// （补丁只 hook GtkHeaderBar，自定义 Box 可绕过），高度 36px、窗口按钮
// 36x36（20px 图标），颜色由 Flutter 侧经 com.example.hopp/window 通道的
// updateTitleBar 方法下发 {dark, background, foreground} 实时跟随主题：
// dark 驱动 gtk-application-prefer-dark-theme（影响对话框等系统控件），
// background/foreground 用 GtkCssProvider 直控标题栏（对齐 app token）。
static GtkCssProvider* g_titlebar_css = nullptr;
static GtkWindow* g_main_window = nullptr;
static GtkImage* g_maximize_image = nullptr;

static void apply_titlebar_css(const gchar* background,
                               const gchar* foreground,
                               const gchar* separator) {
  if (g_titlebar_css == nullptr) {
    g_titlebar_css = gtk_css_provider_new();
    gtk_style_context_add_provider_for_screen(
        gdk_screen_get_default(), GTK_STYLE_PROVIDER(g_titlebar_css),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  }
  g_autofree gchar* css = nullptr;
  if (background != nullptr && foreground != nullptr && separator != nullptr) {
    css = g_strdup_printf(
        ".titlebar { background-color: %s; color: %s; min-height: 36px;"
        " padding: 0 0 0 12px; border-bottom: 1px solid %s; }"
        ".titlebar button.hopp-titlebutton { min-width: 36px; min-height: 36px;"
        " margin: 0; padding: 0; background-color: transparent; border: none;"
        " box-shadow: none; color: %s; }"
        ".titlebar button.hopp-titlebutton:hover {"
        " background-color: alpha(%s, 0.12); }",
        background, foreground, separator, foreground, foreground);
  } else {
    css = g_strdup(
        ".titlebar { min-height: 36px; padding: 0 0 0 12px;"
        " border-bottom: 1px solid alpha(#808080, 0.25); }"
        ".titlebar button.hopp-titlebutton { min-width: 36px; min-height: 36px;"
        " margin: 0; padding: 0; background-color: transparent; border: none;"
        " box-shadow: none; }");
  }
  gtk_css_provider_load_from_data(g_titlebar_css, css, -1, nullptr);
}

static void on_titlebar_close_clicked(GtkButton* button, gpointer user_data) {
  gtk_window_close(g_main_window);
}

static void on_titlebar_minimize_clicked(GtkButton* button, gpointer user_data) {
  gtk_window_iconify(g_main_window);
}

static void on_titlebar_maximize_clicked(GtkButton* button, gpointer user_data) {
  if (gtk_window_is_maximized(g_main_window)) {
    gtk_window_unmaximize(g_main_window);
  } else {
    gtk_window_maximize(g_main_window);
  }
}

// 最大化时把按钮图标换成还原图标
static gboolean on_window_state_changed(GtkWidget* widget,
                                        GdkEventWindowState* event,
                                        gpointer user_data) {
  if ((event->changed_mask & GDK_WINDOW_STATE_MAXIMIZED) &&
      g_maximize_image != nullptr) {
    gtk_image_set_from_icon_name(
        g_maximize_image,
        (event->new_window_state & GDK_WINDOW_STATE_MAXIMIZED)
            ? "window-restore-symbolic"
            : "window-maximize-symbolic",
        GTK_ICON_SIZE_MENU);
    gtk_image_set_pixel_size(g_maximize_image, 20);
  }
  return FALSE;
}

// 标题栏拖动移动窗口 / 双击切换最大化
static gboolean on_titlebar_button_press(GtkWidget* widget,
                                         GdkEventButton* event,
                                         gpointer user_data) {
  if (event->button != GDK_BUTTON_PRIMARY) {
    return FALSE;
  }
  if (event->type == GDK_DOUBLE_BUTTON_PRESS) {
    on_titlebar_maximize_clicked(nullptr, nullptr);
  } else if (event->type == GDK_BUTTON_PRESS) {
    gtk_window_begin_move_drag(g_main_window, event->button,
                               static_cast<gint>(event->x_root),
                               static_cast<gint>(event->y_root), event->time);
  }
  return TRUE;
}

static GtkWidget* create_titlebar_button(const gchar* icon_name,
                                         GCallback clicked_cb) {
  GtkWidget* image = gtk_image_new_from_icon_name(icon_name, GTK_ICON_SIZE_MENU);
  gtk_image_set_pixel_size(GTK_IMAGE(image), 20);
  GtkWidget* button = gtk_button_new();
  gtk_button_set_image(GTK_BUTTON(button), image);
  gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
  // 不用主题的 titlebutton class（deepin 主题会用它覆盖成 PNG 背景小图标）
  gtk_style_context_add_class(gtk_widget_get_style_context(button),
                              "hopp-titlebutton");
  g_signal_connect(button, "clicked", clicked_cb, nullptr);
  return button;
}

// 用普通 GtkBox 构建标题栏并装到窗口上（替代 GtkHeaderBar，见上方注释）
static void install_custom_titlebar(GtkWindow* window) {
  g_main_window = window;

  GtkWidget* bar = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_widget_set_name(bar, "hopp-titlebar");

  GtkWidget* title = gtk_label_new("hopp");
  gtk_style_context_add_class(gtk_widget_get_style_context(title), "title");
  gtk_widget_set_hexpand(title, TRUE);
  gtk_box_pack_start(GTK_BOX(bar), title, TRUE, TRUE, 0);

  // pack_end 逆序放入：close 在最右
  gtk_box_pack_end(GTK_BOX(bar),
                   create_titlebar_button("window-close-symbolic",
                                          G_CALLBACK(on_titlebar_close_clicked)),
                   FALSE, FALSE, 0);
  GtkWidget* maximize_button =
      create_titlebar_button("window-maximize-symbolic",
                             G_CALLBACK(on_titlebar_maximize_clicked));
  g_maximize_image = GTK_IMAGE(gtk_button_get_image(GTK_BUTTON(maximize_button)));
  gtk_box_pack_end(GTK_BOX(bar), maximize_button, FALSE, FALSE, 0);
  gtk_box_pack_end(GTK_BOX(bar),
                   create_titlebar_button("window-minimize-symbolic",
                                          G_CALLBACK(on_titlebar_minimize_clicked)),
                   FALSE, FALSE, 0);

  gtk_widget_add_events(bar, GDK_BUTTON_PRESS_MASK);
  g_signal_connect(bar, "button-press-event",
                   G_CALLBACK(on_titlebar_button_press), nullptr);
  g_signal_connect(window, "window-state-event",
                   G_CALLBACK(on_window_state_changed), nullptr);

  gtk_widget_show_all(bar);
  gtk_window_set_titlebar(window, bar);
}

static void window_channel_method_call_handler(FlMethodChannel* channel,
                                               FlMethodCall* call,
                                               gpointer user_data) {
  const gchar* method = fl_method_call_get_name(call);
  if (g_strcmp0(method, "updateTitleBar") == 0) {
    FlValue* args = fl_method_call_get_args(call);
    gboolean dark = FALSE;
    const gchar* background = nullptr;
    const gchar* foreground = nullptr;
    const gchar* separator = nullptr;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* value = fl_value_lookup_string(args, "dark");
      if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL) {
        dark = fl_value_get_bool(value);
      }
      value = fl_value_lookup_string(args, "background");
      if (value != nullptr &&
          fl_value_get_type(value) == FL_VALUE_TYPE_STRING) {
        background = fl_value_get_string(value);
      }
      value = fl_value_lookup_string(args, "foreground");
      if (value != nullptr &&
          fl_value_get_type(value) == FL_VALUE_TYPE_STRING) {
        foreground = fl_value_get_string(value);
      }
      value = fl_value_lookup_string(args, "separator");
      if (value != nullptr &&
          fl_value_get_type(value) == FL_VALUE_TYPE_STRING) {
        separator = fl_value_get_string(value);
      }
    }
    GtkSettings* settings = gtk_settings_get_default();
    if (settings != nullptr) {
      g_object_set(settings, "gtk-application-prefer-dark-theme", dark,
                   nullptr);
    }
    apply_titlebar_css(background, foreground, separator);
    fl_method_call_respond_success(call, nullptr, nullptr);
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
  }
}

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

  // 自定义标题栏（GtkBox，不用 GtkHeaderBar——Deepin 的 GTK3 补丁会把
  // headerbar 锁定到 ~60px 且其子元素不受 CSS 控制，详见上方注释）；
  // 颜色由 Flutter 侧经 updateTitleBar 通道跟随主题。
  gtk_window_set_title(window, "hopp");
  install_custom_titlebar(window);
  // Flutter 侧同步主题前先应用基础样式（高度/按钮/中性分割线），颜色随后下发。
  apply_titlebar_css(nullptr, nullptr, nullptr);

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

  // 标题栏主题同步通道（复用 com.example.hopp/window，与 macOS 窗口控制同名）
  g_autoptr(FlStandardMethodCodec) window_codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) window_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "com.example.hopp/window", FL_METHOD_CODEC(window_codec));
  fl_method_channel_set_method_call_handler(
      window_channel, window_channel_method_call_handler, nullptr, nullptr);

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
  g_clear_object(&g_titlebar_css);
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
