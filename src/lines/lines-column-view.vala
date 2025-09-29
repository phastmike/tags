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
    [GtkTemplate (ui = "/io/github/phastmike/tags/lines/lines-column-view.ui")]
    public class LinesColumnView : Gtk.Box {
        [GtkChild]
        public Gtk.ColumnView column_view;
        [GtkChild]
        public Gtk.ScrolledWindow scrolled;
        [GtkChild]
        public Gtk.ColumnViewColumn column_line_number;
        [GtkChild]
        public Gtk.ColumnViewColumn column_line_text;

        public LineStore lines;
        public Gtk.MultiSelection selection_model;

        public LinesColumnView (LineStore lines) {
            this.lines = lines;

            selection_model = new Gtk.MultiSelection (lines.store as GLib.ListModel);

            column_view.set_model (selection_model);
            //column_view.remove_column (column_line_number);
            // to hide/show must remove all and re-add
            //column_view.append_column (column_line_number);

            // NOTE: Hide header hack - It works
            var header = column_view.get_first_child ();
            header.set_visible (false);
        }

        private void ui_css_add_styles_to_provider () {
            var preferences = Preferences.instance ();
            var provider_css = new Gtk.CssProvider ();

            provider_css.load_from_string (""" 
                columnview {
                    padding: 0px;
                }

                .line-number {
                /*.line-number:not(:hover):not(:selected) {*/
                    color: %s;
                    background-color: %s;
                }

                .line-number:selected {
                    font-weight: 700;
                }
            """.printf (preferences.ln_fg_color, preferences.ln_bg_color));

            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                provider_css,
                //Gtk.STYLE_PROVIDER_PRIORITY_USER);
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        [GtkCallback]
        private void line_number_setup_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            var label = new Gtk.Label (null);
            label.xalign = 1;
            listitem.child = label;
            ui_css_add_styles_to_provider ();
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
            label.set_text (line.text);
            //label.set_tooltip_text ("%u".printf (listitem.position + 1));
            //ui_css_add_styles_to_provider ();
            //listitem.add_css_class ("line-number");
        }
    }
}
