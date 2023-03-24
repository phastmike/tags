/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * preferences-window.vala
 *
 * Preferences Window
 *
 * José Miguel Fonte
 */

namespace Tagger {
    [GtkTemplate (ui = "/org/ampr/ct1enq/tagger/preferences-window.ui")]
    public class PreferencesWindow : Gtk.Window {
        [GtkChild]
        unowned Gtk.ColorButton button_fg_color;
        [GtkChild]
        unowned Gtk.ColorButton button_bg_color;
        [GtkChild]
        unowned Gtk.Switch switch_tags_autoload;

        public PreferencesWindow (Gtk.Application app) {
            Object(application: app, transient_for: app.active_window, modal: true);

            var preferences = Preferences.instance ();

            var rgb = Gdk.RGBA ();

            if (rgb.parse (preferences.ln_fg_color)) {
                button_fg_color.set_rgba(rgb);
            }

            if (rgb.parse (preferences.ln_bg_color)) {
                button_bg_color.set_rgba(rgb);
            }

            button_fg_color.color_set.connect (() => {
                preferences.ln_fg_color = button_fg_color.get_rgba ().to_string ();
            });

            button_bg_color.color_set.connect (() => {
                preferences.ln_bg_color = button_bg_color.get_rgba ().to_string ();
            });

            switch_tags_autoload.set_active (preferences.tags_autoload);
            preferences.bind_property("tags_autoload", switch_tags_autoload, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        }
    }
}
