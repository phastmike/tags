/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * lines-column-view.vala
 *
 * The Column view containing the document lines
 * Two ColumnViewColumns, line number and text.
 * No headers, Multiple line selection ...
 *
 * José Miguel Fonte
 */

namespace Tags {
    [GtkTemplate (ui = "/io/github/phastmike/tags/ui/lines-column-view.ui")]
    public class LinesColumnView : Gtk.Box {
        [GtkChild]
        public Gtk.ColumnView column_view;
        [GtkChild]
        public Gtk.ScrolledWindow scrolled;
        [GtkChild]
        public Gtk.ColumnViewColumn column_line_number;
        [GtkChild]
        public Gtk.ColumnViewColumn column_line_text;

        public ListModel lines;
        public Gtk.MultiSelection selection_model;

        public delegate ColorScheme? GetLineColorSchemeFunc (string text);
        public GetLineColorSchemeFunc? delegate_get_line_color_scheme_func = null;

        public LinesColumnView (GLib.ListModel model) {
            this.lines = model;

            selection_model = new Gtk.MultiSelection (model);

            column_view.set_model (selection_model);
            //column_view.remove_column (column_line_number);
            // to hide/show must remove all and re-add
            //column_view.append_column (column_line_number);

            // NOTE: Hide header hack - It works
            var header = column_view.get_first_child ();
            header.set_visible (false);
        }

        public void show_line_numbers (bool show) {
            if (show) {
                column_line_number.visible = true;
            } else {
                column_line_number.visible = false;
            }
        }

        public string get_selected_lines_as_string () {
            var str = new StringBuilder ();
            var bitset = selection_model.get_selection ();
            for (uint i = 0; i < bitset.get_size (); i++) {
                var line = selection_model.get_item (bitset.get_nth (i)) as Line;
                str.append (line.text);
                str.append ("\n");
            }
            return str.str;
        }


        private void ui_css_add_styles_to_provider (string klassname, ColorScheme color_scheme) {
            var provider_css = new Gtk.CssProvider ();

            provider_css.load_from_string (""" 
                .%s {
                    color: %s;
                    background-color: %s;
                }
            """.printf (klassname, color_scheme.fg.to_string (), color_scheme.bg.to_string ()));

            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                provider_css,
                //Gtk.STYLE_PROVIDER_PRIORITY_USER);
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        [GtkCallback]
        private void line_number_setup_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            listitem.activatable = false;
            var label = new Gtk.Label (null);
            label.xalign = 1;
            listitem.child = label;
            //ui_css_add_styles_to_provider ();
            //label.add_css_class ("line-number");
            label.add_css_class ("dimmed");
        }

        [GtkCallback]
        private void line_number_bind_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            var label = listitem.child as Gtk.Label;
            var line = listitem.item as Line;
            label.set_text ("%u".printf (line.number));
            //ui_css_add_styles_to_provider ();
            //listitem.child.add_css_class ("line-number");
        }

        [GtkCallback]
        private void line_text_setup_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            //listitem.set_activatable (false);
            var label = new Gtk.Label (null);
            label.xalign = 0;
            listitem.child = label;
            //ui_css_add_styles_to_provider ();
            //label.add_css_class ("line-number");
        }

        [GtkCallback]
        private void line_text_bind_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            var label = listitem.child as Gtk.Label;
            var line = listitem.item as Line;
            string text = line.text;
            label.set_text (text);
            //label.set_tooltip_text ("%u".printf (listitem.position + 1));
            //ui_css_add_styles_to_provider ();
            //listitem.add_css_class ("line-number");
            if (delegate_get_line_color_scheme_func != null) {
                ColorScheme? cs = null;
                cs = delegate_get_line_color_scheme_func (text);
                if (cs != null) {
                    ui_css_add_styles_to_provider ("line-number-%u".printf (line.number), cs);
                    string klassname = "line-number-%u".printf (line.number);
                    listitem.child.add_css_class (klassname);
                    //listitem.child.add_css_class ("card");
                } else {
                    string klassname = "line-number-%u".printf (line.number);
                    listitem.child.remove_css_class (klassname);
                    //listitem.child.remove_css_class ("card");
                }
            }
        }
    }
}
