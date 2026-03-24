using Gtk;
using Wnck;

public class DockApp : Gtk.Application {
    public DockApp() {
        Object(application_id: Config.APP_ID);
    }

    public override void activate() {
        var win = this.active_window;
        if (win == null) {
            win = new ModernDock(this);
        }
        win.present();
    }
}

int main(string[] args) {
    // 起動前にWMへ「これはページャー・ドック系のアプリだよ」と宣言する
    Wnck.set_client_type(Wnck.ClientType.PAGER);
    
    var app = new DockApp();
    return app.run(args);
}