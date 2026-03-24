using GLib;

namespace Animation {
    public class Easing {
        public static double linear(double t) { return t; }
        public static double ease_out_quad(double t) { return t * (2.0 - t); }
        public static double ease_out_cubic(double t) { return 1.0 - Math.pow(1.0 - t, 3.0); }
        public static double ease_out_back(double t) {
            double c1 = 1.70158;
            double c3 = c1 + 1.0;
            return 1.0 + c3 * Math.pow(t - 1.0, 3.0) + c1 * Math.pow(t - 1.0, 2.0);
        }
    }

    public class Animator {
        public delegate void UpdateCallback(double val);
        public delegate void CompleteCallback();

        private double duration;
        private UpdateCallback update_cb;
        private CompleteCallback? complete_cb;
        private double start_time = 0;
        private uint timer_id = 0;
        private string easing_func;

        public Animator(int duration_ms, owned UpdateCallback update_cb, owned CompleteCallback? complete_cb = null, string easing_func = "ease_out_quad") {
            this.duration = duration_ms / 1000.0;
            this.update_cb = (owned) update_cb;
            this.complete_cb = (owned) complete_cb;
            this.easing_func = easing_func;
        }

        public void start() {
            stop();
            this.start_time = (double) GLib.get_monotonic_time() / 1000000.0;
            this.timer_id = GLib.Timeout.add(16, this.tick);
        }

        public void stop() {
            if (this.timer_id != 0) {
                GLib.Source.remove(this.timer_id);
                this.timer_id = 0;
            }
        }

        private bool tick() {
            double current_time = (double) GLib.get_monotonic_time() / 1000000.0;
            double elapsed = current_time - this.start_time;
            double progress = double.min(elapsed / this.duration, 1.0);

            double eased_value = 0;
            if (this.easing_func == "ease_out_back") eased_value = Easing.ease_out_back(progress);
            else if (this.easing_func == "ease_out_cubic") eased_value = Easing.ease_out_cubic(progress);
            else eased_value = Easing.ease_out_quad(progress);

            this.update_cb(eased_value);

            if (progress >= 1.0) {
                if (this.complete_cb != null) this.complete_cb();
                this.timer_id = 0;
                return false;
            }
            return true;
        }
    }
}