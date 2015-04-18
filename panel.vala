/*
 * BudgiePanel.vala
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

public enum PanelPosition
{
    BOTTOM = 0,
    TOP,
    LEFT,
    RIGHT
}

public class Slat : Gtk.ApplicationWindow
{

    Gdk.Rectangle scr;
    int intended_height = 32;
    Gdk.Rectangle small_scr;
    Gdk.Rectangle orig_scr;

    Gtk.Box layout;

    PanelPosition position = PanelPosition.TOP;

    public Slat(Gtk.Application? app)
    {
        Object(application: app, type_hint: Gdk.WindowTypeHint.DOCK);
        destroy.connect(Gtk.main_quit);

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("Compositing not available, things will Look Bad (TM)");
        } else {
            set_visual(vis);
        }
        resizable = false;
        app_paintable = true;

        // TODO: Track
        var mon = screen.get_primary_monitor();
        screen.get_monitor_geometry(mon, out orig_scr);

        /* Smaller.. */
        small_scr = orig_scr;
        small_scr.height = intended_height;

        scr = small_scr;

        layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        add(layout);
        layout.valign = Gtk.Align.START;

        demo_code();

        realize();
        set_struts();
        // Revisit to account for multiple monitors..
        move(0, 0);
        show_all();
        set_expanded(false);
        //present();
    }

    Gtk.MenuButton? mbutton(string title)
    {
        var label = new Gtk.Label(title);
        label.use_markup = true;
        var button = new Gtk.MenuButton();
        button.use_popover = true;
        button.add(label);
        return button;
    }

    void demo_code()
    {
        var button = mbutton("Button 1");
        layout.pack_start(button, false, false, 0);
        var menu = new Menu();
        var action = new PropertyAction("dark-theme", get_settings(), "gtk-application-prefer-dark-theme");
        application.add_action(action);
        menu.append("Dark theme", "app.dark-theme");
        button.menu_model = menu;

        register_menu_button(button);
    }

    void register_menu_button(Gtk.MenuButton? button)
    {
        if (button == null || !button.use_popover) {
            return;
        }
        button.can_focus = false;

        button.popover.notify["visible"].connect(()=> {
            if (button.popover.get_visible()) {
                set_expanded(true);
            } else {
                set_expanded(false);
            }
        });
    }

    public override void get_preferred_width(out int m, out int n)
    {
        m = scr.width;
        n = scr.width;
    }
    public override void get_preferred_width_for_height(int h, out int m, out int n)
    {
        m = scr.width;
        n = scr.width;
    }

    public override void get_preferred_height(out int m, out int n)
    {
        m = scr.height;
        n = scr.height;
    }
    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = scr.height;
        n = scr.height;
    }

    public void set_expanded(bool expanded)
    {
        if (!expanded) {
            scr = small_scr;
        } else {
            scr = orig_scr;
        }
        queue_resize();
        while (Gtk.events_pending()) {
            Gtk.main_iteration();
        }
        if (expanded) {
            present();
        }
    }

    protected void set_struts()
    {
        Gdk.Atom atom;
        long struts[12];
        var primary_monitor_rect = orig_scr;
        bool hidden_struts = false;
        /*
        strut-left strut-right strut-top strut-bottom
        strut-left-start-y   strut-left-end-y
        strut-right-start-y  strut-right-end-y
        strut-top-start-x    strut-top-end-x
        strut-bottom-start-x strut-bottom-end-x
        */

        if (!get_realized()) {
            return;
        }

        long panel_size = intended_height;

        if (hidden_struts) {
            panel_size = 1;
        }

        // Struts dependent on position
        switch (position) {
            case PanelPosition.TOP:
                struts = { 0, 0, primary_monitor_rect.y+panel_size, 0,
                    0, 0, 0, 0,
                    primary_monitor_rect.x, primary_monitor_rect.x+primary_monitor_rect.width,
                    0, 0
                };
                break;
            case PanelPosition.LEFT:
                struts = { panel_size, 0, 0, 0,
                    primary_monitor_rect.y, primary_monitor_rect.y+primary_monitor_rect.height, 
                    0, 0, 0, 0, 0, 0
                };
                break;
            case PanelPosition.RIGHT:
                struts = { 0, panel_size, 0, 0,
                    0, 0,
                    primary_monitor_rect.y, primary_monitor_rect.y+primary_monitor_rect.height,
                    0, 0, 0, 0
                };
                break;
            case PanelPosition.BOTTOM:
            default:
                struts = { 0, 0, 0, 
                    (screen.get_height()-primary_monitor_rect.height-primary_monitor_rect.y) + panel_size,
                    0, 0, 0, 0, 0, 0, 
                    primary_monitor_rect.x, primary_monitor_rect.x + primary_monitor_rect.width
                };
                break;
        }

        // all relevant WMs support this, Mutter included
        atom = Gdk.Atom.intern("_NET_WM_STRUT_PARTIAL", false);
        Gdk.property_change(get_window(), atom, Gdk.Atom.intern("CARDINAL", false),
            32, Gdk.PropMode.REPLACE, (uint8[])struts, 12);
    }
}

} // End namespace

static Budgie.Slat instance = null;

static void app_start(Application? app)
{
    if (instance == null) {
        instance = new Budgie.Slat(app as Gtk.Application);
    }
}

public static int main(string[] args)
{
    var app = new Gtk.Application("com.solus-project.Slat", 0);
    app.activate.connect(app_start);

    return app.run();
}
