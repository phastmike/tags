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
    [GtkTemplate (ui = "/org/ampr/ct1enq/tags/preferences-window.ui")]
    public class PreferencesWindow : Adw.PreferencesWindow {
        [GtkChild]
        private unowned Gtk.ColorDialogButton button_fg_color;
        [GtkChild]
        private unowned Gtk.ColorDialogButton button_bg_color;
        [GtkChild]
        private unowned Adw.ActionRow row_autoload_tags; 
        [GtkChild]
        private unowned Gtk.Switch switch_tags_autoload;
        [GtkChild]
        private unowned Gtk.Label label_sample_example;

        private const string css_class = "color_scheme_example";

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

            var dialog_fg_color = new Gtk.ColorDialog ();
            dialog_fg_color.set_modal (true);
            dialog_fg_color.set_with_alpha (false);
            dialog_fg_color.set_title ("Select the foreground color");
            button_fg_color.set_dialog (dialog_fg_color); 

            var dialog_bg_color = new Gtk.ColorDialog ();
            dialog_bg_color.set_modal (true);
            dialog_bg_color.set_with_alpha (false);
            dialog_bg_color.set_title ("Select the background color");
            button_bg_color.set_dialog (dialog_bg_color); 

            button_fg_color.notify["rgba"].connect (() => {
                preferences.ln_fg_color = button_fg_color.get_rgba ().to_string ();
                set_label_example_colors ();
            });

            button_bg_color.notify["rgba"].connect (() => {
                preferences.ln_bg_color = button_bg_color.get_rgba ().to_string ();
                set_label_example_colors ();
            });

            row_autoload_tags.activated.connect (() => {
                switch_tags_autoload.set_active(!switch_tags_autoload.get_active ());
            });

            switch_tags_autoload.set_active (preferences.tags_autoload);
            preferences.bind_property("tags_autoload", switch_tags_autoload, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

            set_label_example_colors ();
        }

        private void set_label_example_colors () {
            var fg = button_fg_color.get_rgba ();
            var bg = button_bg_color.get_rgba ();

            var fg_web = "#%02x%02x%02x".
                    printf((uint) (fg.red * 255), (uint) (fg.green * 255), (uint) (fg.blue * 255));
            var bg_web = "#%02x%02x%02x".
                    printf((uint) (bg.red * 255), (uint) (bg.green * 255), (uint) (bg.blue * 255));

            string? lstyle = """
                label.%s {
                    padding: 6px 8px;
                    background-color: %s;
                    border-radius: 7px;
                    color: %s;
                    font-size: 0.8333em;
                }
            """.printf (PreferencesWindow.css_class, bg_web, fg_web);

            var provider = new Gtk.CssProvider ();
            provider.load_from_data (lstyle.data);
            label_sample_example.add_css_class (PreferencesWindow.css_class);
            Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        }

    }
}
