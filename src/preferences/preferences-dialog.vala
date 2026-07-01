/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * preferences-window.vala
 *
 * Preferences Window
 *
 * José Miguel Fonte
 */

namespace Tags {
    [GtkTemplate (ui = "/io/github/phastmike/tags/ui/preferences-dialog.ui")]
    public class PreferencesDialog : Adw.PreferencesDialog {
        [GtkChild]
        private unowned Adw.ActionRow row_autoload_tags; 
        [GtkChild]
        private unowned Gtk.Switch switch_tags_autoload;
        [GtkChild]
        private unowned Adw.SwitchRow row_ln_visible;
        [GtkChild]
        private unowned Gtk.Label label_sample_example;
        [GtkChild]
        private unowned Adw.SwitchRow row_minimap_visible;
        [GtkChild]
        private unowned Adw.SpinRow row_wrap_nlines;

        private const string css_class = "color_scheme_example";

        public PreferencesDialog () {
            var preferences = Preferences.instance ();
            var rgb = Gdk.RGBA ();

            row_autoload_tags.activated.connect (() => {
                switch_tags_autoload.set_active(!switch_tags_autoload.get_active ());
            });

            preferences.bind_property("ln_visible", row_ln_visible, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            row_ln_visible.set_active (preferences.ln_visible);

            preferences.bind_property("tags_autoload", switch_tags_autoload, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            switch_tags_autoload.set_active (preferences.tags_autoload);

            preferences.bind_property("minimap_visible", row_minimap_visible, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            row_minimap_visible.set_active (preferences.minimap_visible);

            preferences.bind_property("wrap_nlines", row_wrap_nlines.adjustment, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            row_wrap_nlines.set_value (preferences.wrap_nlines);
        }
    }
}
