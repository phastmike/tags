/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * tag-dialog-window.vala
 *
 * Dialog Window to Add/Edit a Tag 
 * 
 *
 * José Miguel Fonte
 */

namespace Tagger {
    [GtkTemplate (ui = "/org/ampr/ct1enq/tags/tag-dialog-window.ui")]
    public class TagDialogWindow : Gtk.Window {
        [GtkChild]
        private unowned Gtk.Button button_ok;
        [GtkChild]
        private unowned Gtk.Button button_cancel;
        [GtkChild]
        private unowned Gtk.Button button_delete;
        [GtkChild]
        private unowned Gtk.ColorDialogButton button_fg_color;
        [GtkChild]
        private unowned Gtk.ColorDialogButton button_bg_color;
        [GtkChild]
        private unowned Adw.EntryRow entry_tag_pattern;
        [GtkChild]
        private unowned Adw.EntryRow entry_tag_name;
        [GtkChild]
        private unowned Gtk.Label label_sample_example;
        [GtkChild]
        private unowned Adw.ActionRow row_regex;
        [GtkChild]
        private unowned Adw.ActionRow row_case;
        [GtkChild]
        private unowned Adw.ActionRow row_atop;
        [GtkChild]
        private unowned Gtk.Switch switch_regex;
        [GtkChild]
        private unowned Gtk.Switch switch_case;
        [GtkChild]
        private unowned Gtk.Switch switch_atop;

        private const string css_class = "color_scheme_example";

        public signal void added (Tag tag, bool add_to_top);
        public signal void edited (Tag tag);
        public signal void deleted (Tag tag);

        construct {
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

            button_cancel.clicked.connect (this.destroy);

            button_fg_color.notify["rgba"].connect (set_label_example_colors);
            button_bg_color.notify["rgba"].connect (set_label_example_colors);

            string? lstyle = """
                text {
                    /*font-size: 0.8333em;*/
                    font-family: monospace;
                }

                text selection {
                    background-color: #3584e4;
                    color: @accent_fg_color;
                }
            """;

            var provider = new Gtk.CssProvider ();
            provider.load_from_data (lstyle.data);
            this.add_css_class (TagDialogWindow.css_class);
            Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);

            row_regex.activated.connect (() => {
                switch_regex.set_active(!switch_regex.get_active ());
            });

            row_case.activated.connect (() => {
                switch_case.set_active(!switch_case.get_active ());
            });

            row_atop.activated.connect (() => {
                switch_atop.set_active(!switch_atop.get_active ());
            });
        }

        public TagDialogWindow (Gtk.Application app, string? text = null) {
            Object(application: app, transient_for: app.active_window, modal: true);

            button_ok.clicked.connect (() => {
                var pattern = entry_tag_pattern.get_text ();
                var description = entry_tag_name.get_text ();
                var fg_color = button_fg_color.get_rgba ();
                var bg_color = button_bg_color.get_rgba ();

                var color_scheme = new ColorScheme ("default", fg_color, bg_color);
                var tag = new Tag (pattern, description, color_scheme); 
                // Use a builder class
                tag.is_regex = switch_regex.get_active ();
                tag.is_case_sensitive = switch_case.get_active ();

                bool add_to_top = switch_atop.get_active ();

                added (tag, add_to_top);

                this.destroy ();
            });
            
            entry_tag_pattern.changed.connect (validate_entries);
            entry_tag_name.changed.connect (validate_entries);
            set_label_example_colors ();

            if (text != null) {
                entry_tag_pattern.set_text (text);
            }
        }

        public TagDialogWindow.for_editing (Gtk.Application app, Tag tag) {
            Object(application: app, transient_for: app.active_window, modal: true);

            button_ok.set_label ("_Edit");
            button_ok.set_sensitive (true);

            button_delete.set_visible (true);

            row_atop.set_visible (false);

            entry_tag_pattern.set_text (tag.pattern); 
            entry_tag_name.set_text (tag.description);
            button_fg_color.set_rgba (tag.colors.fg);
            button_bg_color.set_rgba (tag.colors.bg);

            this.set_default_size (600, 600);

            button_ok.clicked.connect (() => { 
                tag.pattern = entry_tag_pattern.get_text ();
                tag.description = entry_tag_name.get_text ();
                tag.colors.fg = button_fg_color.get_rgba ();
                tag.colors.bg = button_bg_color.get_rgba ();
                tag.is_regex = switch_regex.get_active ();
                tag.is_case_sensitive = switch_case.get_active ();
                edited (tag);
                this.destroy ();
            });
            
            button_delete.clicked.connect (() => {
                deleted(tag);
                this.destroy ();
            });
            
            entry_tag_pattern.changed.connect (validate_entries);
            entry_tag_name.changed.connect (validate_entries);
            set_label_example_colors ();

            switch_regex.set_active(tag.is_regex);
            switch_case.set_active(tag.is_case_sensitive);
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
            """.printf (TagDialogWindow.css_class, bg_web, fg_web);

            var provider = new Gtk.CssProvider ();
            provider.load_from_data (lstyle.data);
            label_sample_example.add_css_class (TagDialogWindow.css_class);
            Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        }

        private void validate_entries () {
            if (entry_tag_pattern.get_text ().length != 0) {
                button_ok.set_sensitive (true);
            } else {
                button_ok.set_sensitive (false);
            }
        }
    }
}
