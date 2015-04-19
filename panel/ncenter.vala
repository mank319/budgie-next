/*
 * ncenter.vala
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class HeaderWidget : Gtk.EventBox
{
    private string _title;

    public string title {
        public set {
            this._title = value;
            this.label.set_markup(title);
        }
        public get {
            return this._title;
        }
    }

    private Gtk.Label label;

    public HeaderWidget(string title)
    {
        label = new Gtk.Label(title);
        add(label);
        this.title = title;
        label.halign = Gtk.Align.START;

        label.margin = 10;
        show_all();

        get_style_context().add_class("header-widget");
    }
}


public class NCenter : Gtk.Window
{
    Gtk.Box layout;
    Gtk.Box main_layout;

    // Hacky, but just says how far to offset our window.
    int offset;

    public NCenter(int offset)
    {
        Object(type_hint: Gdk.WindowTypeHint.DOCK);
        destroy.connect(Gtk.main_quit);
        this.offset = offset;

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("No RGBA functionality");
        } else {
            set_visual(vis);
        }

        resizable = false;
        set_keep_above(true);

        layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        add(main_layout);

        var shadow = new Budgie.VShadowBlock();
        main_layout.pack_start(shadow, false, false, 0);
        main_layout.pack_start(layout, true, true, 0);

        layout.get_style_context().add_class("notification-center");


        /* Demo code */
        var header = new HeaderWidget("Media");
        layout.pack_start(header, false, false, 2);
        header.margin_top = 10;
        header.margin_bottom = 10;

        var mpris = new MprisWidget();
        mpris.margin_left = 20;
        layout.pack_start(mpris, false, false, 0);

        header = new HeaderWidget("Audio");
        layout.pack_start(header, false, false, 2);
        header.margin_top = 20;
        header.margin_bottom = 10;
        var audio = new AudioPane();
        audio.margin_left = 20;
        audio.margin_right = 20;
        layout.pack_start(audio, false, false, 0);

        layout.show_all();

        placement();
        get_child().show_all();
    }

    /**
     * In future this will handle sliding ncenter into view.. */
    public void set_expanded(bool exp)
    {
        double old_op, new_op;
        if (exp) {
            old_op = 0.0;
            new_op = 1.0;
        } else {
            old_op = 1.0;
            new_op = 0.0;
        }
        opacity = old_op;

        if (exp) {
            show_all();
        }
        var anim = new Budgie.Animation();
        anim.widget = this;
        anim.length = 260 * Budgie.MSECOND;
        anim.tween = Budgie.circ_ease_out;
        anim.changes = new Budgie.PropChange[] {
            Budgie.PropChange() {
                property = "opacity",
                old = old_op,
                @new = new_op
            },
        };

        anim.start((a)=> {
            if (a.widget.opacity == 0.0) {
                a.widget.hide();
            } else {
                (a.widget as Gtk.Window).present();
            }
        });
    }

    void placement()
    {
        Gdk.Rectangle scr;
        var mon = screen.get_primary_monitor();
        screen.get_monitor_geometry(mon, out scr);

        var width = (int) (scr.width * 0.16);
        if (!get_realized()) {
            realize();
        }
        set_size_request(width, scr.height-offset);
        move(scr.x + (scr.width-width), scr.y+offset);
    }
}