using X;
using Gdk;

namespace X11Utils {
    public void apply_strut(Gtk.Window win, int dock_w, int dock_h) {
        var gdk_display = Gdk.Display.get_default();
        if (!(gdk_display is Gdk.X11.Display)) return;

        // ここ！ unowned を付けて「所有権を持たない参照」にするよ
        unowned X.Display display = ((Gdk.X11.Display)gdk_display).get_xdisplay();
        
        var gdk_win = win.get_window();
        if (gdk_win == null) return;
        
        X.Window xid = (X.Window) ((Gdk.X11.Window)gdk_win).get_xid();
        
        var monitor = gdk_display.get_primary_monitor() ?? gdk_display.get_monitor(0);
        var geo = monitor.get_geometry();

        int x = geo.x + (geo.width - dock_w) / 2;
        // y は計算に使わないけど、意味的に残しておくならこう
        // もしくは行ごと消してもOK！

        X.Atom atom_strut = display.intern_atom("_NET_WM_STRUT", false);
        X.Atom atom_strut_partial = display.intern_atom("_NET_WM_STRUT_PARTIAL", false);
        X.Atom atom_cardinal = display.intern_atom("CARDINAL", false);

        long strut[4] = { 0, 0, 0, (long)dock_h };
        long strut_partial[12] = { 0, 0, 0, (long)dock_h, 0, 0, 0, 0, 0, 0, (long)x, (long)(x + dock_w) };

        display.change_property(xid, atom_strut, atom_cardinal, 32, X.PropMode.Replace, (uchar[])strut, 4);
        display.change_property(xid, atom_strut_partial, atom_cardinal, 32, X.PropMode.Replace, (uchar[])strut_partial, 12);
        display.flush();
    }
}