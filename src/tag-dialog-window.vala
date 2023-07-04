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
    [GtkTemplate (ui = "/org/ampr/ct1enq/tagger/tag-dialog-window.ui")]
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
        private unowned Gtk.Entry entry_tag_pattern;
        [GtkChild]
        private unowned Gtk.Entry entry_tag_name;
        [GtkChild]
        private unowned Gtk.Label label_sample_example;
        [GtkChild]
        private unowned Gtk.Switch switch_regex;
        [GtkChild]
        private unowned Gtk.Switch switch_case;

        [GtkChild]
        private unowned Gtk.ListBox list_box_text;
        [GtkChild]
        private unowned Gtk.Text text_pattern;
        [GtkChild]
        private unowned Gtk.Text text_description;

        private const string css_class = "color_scheme_example";

        public signal void added (Tag tag);
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

            /*
            list_box_text.row_activated.connect ((row) => {
                print ("Row selected ... 0x%p\n", row);
                row.set_can_focus (!row.get_can_focus ());
            });
            */
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
                // Use a builder classs
                tag.is_regex = switch_regex.get_active ();
                tag.is_case_sensitive = switch_case.get_active ();

                added (tag);

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

            entry_tag_pattern.set_text (tag.pattern); 
            entry_tag_name.set_text (tag.description);
            button_fg_color.set_rgba (tag.colors.fg);
            button_bg_color.set_rgba (tag.colors.bg);

            
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
            """.printf (this.css_class, bg_web, fg_web);

            var provider = new Gtk.CssProvider ();
            provider.load_from_data (lstyle.data);
            label_sample_example.add_css_class (this.css_class);
            Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        }

        private void validate_entries () {
            if (entry_tag_pattern.get_text_length () != 0) {
                button_ok.set_sensitive (true);
            } else {
                button_ok.set_sensitive (false);
            }
        }
    }
}
