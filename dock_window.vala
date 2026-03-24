using Gtk;
using Gdk;
using Wnck;
using Animation;

class TaskButton : Gtk.Button {
    public Wnck.Window wnck_win;
    
    public TaskButton(Wnck.Window win) {
        this.wnck_win = win;
        this.get_style_context().add_class("app-button");
        
        var icon = win.get_icon();
        if (icon != null) {
            int icon_size = (int)(Config.DOCK_HEIGHT * 0.7);
            var scaled = icon.scale_simple(icon_size, icon_size, Gdk.InterpType.BILINEAR);
            this.add(new Gtk.Image.from_pixbuf(scaled));
        }
        
        this.set_tooltip_text(win.get_name());
        
        // 名前が変わったらツールチップも更新
        win.name_changed.connect(() => {
            this.set_tooltip_text(win.get_name());
        });

        this.clicked.connect(() => {
            if (win.is_active()) {
                win.minimize();
            } else {
                win.activate(0); // 0はタイムスタンプ（すぐにアクティブ化）
            }
        });
    }
}

public class ModernDock : Gtk.ApplicationWindow {
    private Gtk.Box main_box;
    private Gtk.Box center_box;
    private Gtk.Label clock_label;
    private Gtk.CssProvider css_provider;
    private int dock_w = 0;
    private Wnck.Screen wnck_screen;
    private HashTable<ulong, TaskButton> buttons;

    public ModernDock(Gtk.Application app) {
        Object(application: app);
        
        this.set_title("Modern Dock");
        this.set_type_hint(Gdk.WindowTypeHint.DOCK);
        
        Config.load_config();
        this.buttons = new HashTable<ulong, TaskButton>(direct_hash, direct_equal);
        
        this.update_geometry();
        
        this.set_resizable(false);
        this.set_decorated(false);
        this.set_keep_above(true);
        this.stick();
        this.set_skip_taskbar_hint(true);
        this.set_skip_pager_hint(true);
        this.set_app_paintable(true);
        
        var screen = Gdk.Screen.get_default();
        var visual = screen.get_rgba_visual();
        if (visual != null && screen.is_composited()) {
            this.set_visual(visual);
        }

        this.css_provider = new Gtk.CssProvider();
        Gtk.StyleContext.add_provider_for_screen(screen, this.css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        this.update_css();

        this.main_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        this.main_box.get_style_context().add_class("dock-container");
        this.add(this.main_box);

        this.setup_launcher();
        this.setup_taskbar();
        this.setup_status_area();

        GLib.Timeout.add_seconds(1, this.update_clock);

        screen.size_changed.connect(this.on_screen_changed);
        screen.monitors_changed.connect(this.on_screen_changed);
        
        this.realize.connect(() => { 
            this.align_to_bottom(); 
            // 描画された後にWMへのStrut（場所予約）を適用
            X11Utils.apply_strut(this, this.dock_w, Config.DOCK_HEIGHT);
        });
        
        this.setup_wnck();
        this.show_all();
    }

    private void setup_wnck() {
        this.wnck_screen = Wnck.Screen.get_default();
        this.wnck_screen.force_update();
        
        // 既存のウィンドウを読み込む
        foreach (var win in this.wnck_screen.get_windows()) {
            this.add_window(win);
        }

        // ウィンドウの開閉イベント
        this.wnck_screen.window_opened.connect((win) => { this.add_window(win); });
        this.wnck_screen.window_closed.connect((win) => { this.remove_window(win); });
    }

    private void add_window(Wnck.Window win) {
        if (win.is_skip_taskbar() || win.get_window_type() == Wnck.WindowType.DOCK || win.get_window_type() == Wnck.WindowType.DESKTOP) {
            return; // 表示しないウィンドウはスキップ
        }

        ulong xid = win.get_xid();
        if (this.buttons.contains(xid)) return;

        var btn = new TaskButton(win);
        this.buttons.insert(xid, btn);
        this.center_box.pack_start(btn, false, false, 0);
        btn.show_all();

        if (Config.ANIMATION_ENABLED) {
            btn.set_opacity(0.0);
            var anim = new Animator(Config.ANIMATION_DURATION, (val) => {
                btn.set_opacity(val);
            }, () => {
                btn.set_opacity(1.0);
            }, Config.ANIMATION_EASING);
            anim.start();
        }
    }

    private void remove_window(Wnck.Window win) {
        ulong xid = win.get_xid();
        if (!this.buttons.contains(xid)) return;

        var btn = this.buttons.lookup(xid);
        this.buttons.remove(xid);

        if (Config.ANIMATION_ENABLED) {
            var anim = new Animator(Config.ANIMATION_DURATION, (val) => {
                btn.set_opacity(1.0 - val);
            }, () => {
                this.center_box.remove(btn);
                btn.destroy();
            }, Config.ANIMATION_EASING);
            anim.start();
        } else {
            this.center_box.remove(btn);
            btn.destroy();
        }
    }

    private void setup_launcher() {
        var left_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        left_box.set_valign(Gtk.Align.CENTER);
        var launcher_btn = new Gtk.Button();
        launcher_btn.get_style_context().add_class("launcher-button");
        launcher_btn.add(new Gtk.Image.from_icon_name("view-app-grid-symbolic", Gtk.IconSize.MENU));
        
        launcher_btn.clicked.connect(() => {
            try {
                AppInfo.launch_default_for_uri(Config.LAUNCHER_CMD, null);
            } catch (Error e) {
                try { GLib.Process.spawn_command_line_async(Config.LAUNCHER_CMD); } catch (Error e2) {}
            }
        });

        left_box.pack_start(launcher_btn, false, false, 0);
        this.main_box.pack_start(left_box, false, false, 0);
    }

    private void setup_taskbar() {
        this.center_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
        this.center_box.set_halign(Gtk.Align.CENTER);
        this.center_box.set_valign(Gtk.Align.CENTER);
        this.main_box.pack_start(this.center_box, true, false, 0);
    }

    private void setup_status_area() {
        var right_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        right_box.set_valign(Gtk.Align.CENTER);
        var status_container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
        status_container.get_style_context().add_class("status-pill");
        
        this.clock_label = new Gtk.Label("00:00");
        this.clock_label.get_style_context().add_class("clock-label");
        status_container.pack_end(this.clock_label, false, false, 0);
        
        right_box.pack_start(status_container, false, false, 0);
        this.main_box.pack_start(right_box, false, false, 0);
        this.update_clock();
    }

    private void update_css() {
        int radius = (int)(Config.DOCK_HEIGHT * Config.RADIUS_RATIO);
        string css = @"
        window { background-color: transparent; }
        .dock-container {
            background-color: rgba(35, 35, 35, 0.9);
            border-radius: $(radius)px $(radius)px 0px 0px; 
            padding: 0px 10px;
        }
        .launcher-button { background-color: transparent; border: none; border-radius: 50%; padding: 10px; }
        .app-button { background-color: transparent; border: none; border-radius: 12px; padding: 6px; transition: background-color 200ms; }
        .app-button:hover { background-color: rgba(255,255,255,0.1); }
        .clock-label { color: #ffffff; font-weight: bold; font-size: 14px; }
        .status-pill { background-color: rgba(255,255,255,0.1); border-radius: 20px; padding: 0px 12px; }
        ";
        try { this.css_provider.load_from_data(css, -1); } catch (Error e) {}
    }

    private void update_geometry() {
        var display = Gdk.Display.get_default();
        var monitor = display.get_primary_monitor() ?? display.get_monitor(0);
        var rect = monitor.get_geometry();
        this.dock_w = (int)(rect.width * Config.WIDTH_RATIO);
        this.set_default_size(this.dock_w, Config.DOCK_HEIGHT);
    }

    private void align_to_bottom() {
        var display = Gdk.Display.get_default();
        var monitor = display.get_primary_monitor() ?? display.get_monitor(0);
        var geo = monitor.get_geometry();
        
        int x = geo.x + (geo.width - this.dock_w) / 2;
        int y = geo.y + geo.height - Config.DOCK_HEIGHT;
        
        this.move(x, y);
        this.resize(this.dock_w, Config.DOCK_HEIGHT);
    }

    private bool update_clock() {
        var now = new DateTime.now_local();
        this.clock_label.set_text(now.format("%H:%M"));
        return true;
    }

    private void on_screen_changed(Gdk.Screen screen) {
        this.update_geometry();
        this.align_to_bottom();
        X11Utils.apply_strut(this, this.dock_w, Config.DOCK_HEIGHT);
    }
}