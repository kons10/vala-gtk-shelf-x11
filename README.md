# vala-gtk-shelf-x11
コンパイル方法
libwnck を追加したから、コンパイルコマンドはこうなるよ。

必要なパッケージをインストール

Arch Linux系: sudo pacman -S libwnck3

Debian/Ubuntu系: sudo apt install libwnck-3-dev

コンパイル実行！
```bash
valac --pkg gtk+-3.0 --pkg gdk-x11-3.0 --pkg x11 --pkg json-glib-1.0 --pkg libwnck-3.0 -X -DWNCK_I_KNOW_THIS_IS_UNSTABLE main.vala config.vala animation.vala dock_window.vala x11_utils.vala
```

これで main っていう実行ファイルができるから、それを実行してみてね。Wnckのおかげで、ウィンドウのアイコン取得やツールチップの処理が何倍も綺麗になったはずだよ！