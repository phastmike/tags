/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * filter-dialog-window.vala
 *
 * Dialog Window to Add/Edit filter
 * 
 *
 * José Miguel Fonte
 */

namespace Gtat {
    [GtkTemplate (ui = "/org/ampr/ct1enq/gtat/filter-dialog-window.ui")]
    public class FilterDialogWindow : Gtk.Window {
        [GtkChild]
        private unowned Gtk.Button button_ok;
        [GtkChild]
        private unowned Gtk.Button button_cancel;
        [GtkChild]
        private unowned Gtk.ColorButton button_fg_color;
        [GtkChild]
        private unowned Gtk.ColorButton button_bg_color;
        [GtkChild]
        private unowned Gtk.Entry entry_tag_filter;
        [GtkChild]
        private unowned Gtk.Entry entry_tag_name;
        [GtkChild]
        private unowned Gtk.Label label_sample_example;

        public const string example_text = " Lorem ipsum dolor sit amet... ";

        public signal void added (LineFilter filter);

        public FilterDialogWindow (Gtk.Application app, Gtk.Window parent) {
            Object(application: app, transient_for: parent, modal: true);
            
            entry_tag_filter.changed.connect (validate_entries);
            entry_tag_name.changed.connect (validate_entries);
            set_label_example_colors ();

            button_ok.clicked.connect (() => {
                var pattern = entry_tag_filter.get_text ();
                var description = entry_tag_name.get_text ();
                var fg_color = button_fg_color.get_rgba ();
                var bg_color = button_bg_color.get_rgba ();
                
                LineFilter filter = new LineFilter (pattern, description, new ColorScheme ("default", fg_color, bg_color));
                added (filter);
                this.destroy ();
            });
            
            button_cancel.clicked.connect (() => {
                this.destroy ();
            });
            
            button_fg_color.color_set.connect (()=> {
                set_label_example_colors ();
            });
            
            button_bg_color.color_set.connect (()=> {
                set_label_example_colors ();
            });
        }

        private void set_label_example_colors () {
            var fg = button_fg_color.get_rgba ();
            var bg = button_bg_color.get_rgba ();
            
            var fg_web = "#%02x%02x%02x".
                    printf((uint) (fg.red * 255), (uint) (fg.green * 255), (uint) (fg.blue * 255));
            var bg_web = "#%02x%02x%02x".
                    printf((uint) (bg.red * 255), (uint) (bg.green * 255), (uint) (bg.blue * 255));

            string markup = "<span foreground=\"%s\" background=\"%s\">%s</span>".
                    printf(fg_web, bg_web, example_text);

            label_sample_example.set_markup (markup);
        }

        private void validate_entries () {
            if ((entry_tag_filter.get_text_length () != 0) &
                (entry_tag_name.get_text_length () != 0)) {
                button_ok.set_sensitive (true);
            } else {
                button_ok.set_sensitive (false);
            }
        }
    }
}
