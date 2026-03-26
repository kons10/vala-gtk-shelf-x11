using Json;
using GLib;

namespace Config {
    public const string APP_ID = "dock.ams.f5.si";
    public static int DOCK_HEIGHT = 60;
    public static double RADIUS_RATIO = 0.5;
    public static double WIDTH_RATIO = 1.0;
    public static double CONTROL_RATIO = 0.8;
    
    // 初期化をメソッド内で行うため、宣言だけにする
    public static string LAUNCHER_CMD;
    public static bool ANIMATION_ENABLED = true;
    public static int ANIMATION_DURATION = 800;
    public static string ANIMATION_EASING;

    public static void load_config() {
        // デフォルト値をここでセット
        LAUNCHER_CMD = "rofi -show drun";
        ANIMATION_EASING = "ease_out_back";

        string config_dir = Environment.get_user_config_dir() + "/gtk-shelf-x11";
        string config_file = config_dir + "/config.json";

        if (!FileUtils.test(config_file, FileTest.EXISTS)) {
            DirUtils.create_with_parents(config_dir, 0755);
            return;
        }

        try {
            var parser = new Json.Parser();
            parser.load_from_file(config_file);
            var root = parser.get_root().get_object();

            if (root.has_member("DOCK_HEIGHT")) DOCK_HEIGHT = (int)root.get_int_member("DOCK_HEIGHT");
            if (root.has_member("RADIUS_RATIO")) RADIUS_RATIO = root.get_double_member("RADIUS_RATIO");
            if (root.has_member("WIDTH_RATIO")) WIDTH_RATIO = root.get_double_member("WIDTH_RATIO");
            if (root.has_member("LAUNCHER_CMD")) LAUNCHER_CMD = root.get_string_member("LAUNCHER_CMD");
            if (root.has_member("ANIMATION_ENABLED")) ANIMATION_ENABLED = root.get_boolean_member("ANIMATION_ENABLED");
            if (root.has_member("ANIMATION_DURATION")) ANIMATION_DURATION = (int)root.get_int_member("ANIMATION_DURATION");
            if (root.has_member("ANIMATION_EASING")) ANIMATION_EASING = root.get_string_member("ANIMATION_EASING");
        } catch (Error e) {
            print("設定ファイルの読み込みに失敗したよ: %s\n", e.message);
        }
    }
}