valac --pkg gtk+-3.0 utils.vala panel.vala BudgieMenuWindow.vala -o panel --pkg libgnome-menu-3.0 --pkg gio-unix-2.0 -X -DGMENU_I_KNOW_THIS_IS_UNSTABLE
valac --pkg gtk+-3.0 utils.vala MprisClient.vala MprisGui.vala MprisWidget.vala  ncenter.vala   --pkg gio-unix-2.0 -o ncenter
