/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * lines-view.vala
 *
 * The view containing the document lines
 * Two ColumnViewColumns, line number and text.
 * - Table with no headers, (hacc),
 * - Single/Multiple line selection
 *
 *  Adw.Bin > Gtk.ScrolledWindow > Gtk.ColumnView 
 *
 * José Miguel Fonte
 */

namespace Tags {
    [GtkTemplate (ui = "/io/github/phastmike/tags/ui/lines-view.ui")]
    public class LinesView : Adw.Bin {
        [GtkChild]
        public unowned Gtk.ColumnView column_view;
        [GtkChild]
        public unowned Gtk.ScrolledWindow scrolled;
        [GtkChild]
        public unowned Gtk.ColumnViewColumn column_line_number;
        [GtkChild]
        public unowned Gtk.ColumnViewColumn column_line_text;

        public ListModel lines;
        public Gtk.MultiSelection selection_model;

        private bool _wrap_lines = false;
        private uint _wrap_nlines = 2;
        private const int _wrap_height = 18;

        public  bool wrap_lines {
            get { return _wrap_lines; }
            set {
                _wrap_lines = value;
                column_view.set_model (null);
                column_view.set_model (selection_model); 
            }
        }

        public uint wrap_nlines {
            get { return (uint) _wrap_nlines; }
            set {
                    if (value > 0 && value < 11) {
                    _wrap_nlines = value;
                    column_view.set_model (null);
                    column_view.set_model (selection_model); 
                }
            }
        }

        public LinesView (GLib.ListModel model) {
            this.lines = model;
            selection_model = new Gtk.MultiSelection (model);
            column_view.set_model (selection_model);
            wrap_lines = false;

            // Hide ColumnView header hack
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
                //clear_all_tag_styles (label);
                str.append ("\n");
            }
            return str.str;
        }

        [GtkCallback]
        private void line_number_setup_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            listitem.activatable = false;
            var label = new Gtk.Label (null);
            label.xalign = 1;
            listitem.child = label;
            label.add_css_class ("dimmed");
        }

        [GtkCallback]
        private void line_number_bind_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            var label = listitem.child as Gtk.Label;
            var line = listitem.item as Line;
            label.set_text ("%u".printf (line.number));
        }

        [GtkCallback]
        private void line_text_setup_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            var label = new Gtk.Label (null);
            label.xalign = 0;
            label.set_ellipsize (Pango.EllipsizeMode.NONE);
            label.set_wrap_mode (Pango.WrapMode.CHAR);
            listitem.child = label;
        }

        [GtkCallback]
        private void line_text_bind_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            var label = listitem.child as Gtk.Label;

            var line = listitem.item as Line;
            label.set_text (line.text);

            if (_wrap_lines == true) {
                label.set_wrap (true);
                label.set_tooltip_text (line.text);
                label.height_request = (_wrap_height * ((int) _wrap_nlines)) + ((int) _wrap_nlines / 2); 
            } else {
                label.set_wrap (false);
                label.height_request = -1; 
                label.set_tooltip_text (null);
            }

            update_line_tag_style (label, line);

            if (line.sighandler == 0 && line.tag != null) {
                line.sighandler = line.tag.enable_changed.connect (() => {
                    if (label != null && line != null) {
                        update_line_tag_style (label, line);
                    }
                });

            /*
                line.sighandler = line.tag.changed.connect (() => {
                    if (label != null && line != null) {
                        update_line_tag_style (label, line);
                    }
                });

                
                line.sighandler = line.tag_changed.connect (() => {
                    if (label != null && line != null) {
                        update_line_tag_style (label, line);
                    }
                });
                */
            }
        }

        [GtkCallback]
        private void line_text_unbind_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            var label = listitem.child as Gtk.Label;
            var line = listitem.item as Line;

            clear_all_tag_styles (label);

            /*
            if (line.sighandler != 0) {
                line.disconnect (line.sighandler);
                line.sighandler = 0;
            }
            */
        }

        // NOTE: Should be quick, just iterate over tags to remove the styleclasses
        private void clear_all_tag_styles (Gtk.Widget widget) {
            if (widget == null || widget.parent == null) { return; }
            var c = widget.parent;
            if (c.css_classes.length != 0) {
                foreach (var css_class in c.css_classes) {
                    if (css_class.has_prefix (TagContext.STYLE_PREFIX_LINE)) {
                        c.remove_css_class (css_class);
                    }
                }
            }
        }

        private void update_line_tag_style (Gtk.Label label, Line line) { 
            if (line == null || label == null) { return; }

            clear_all_tag_styles (label);

            var tag = line.get_active_tag ();
            if (tag != null) {
                label.parent.add_css_class (TagContext.get_style_name_for_tag (tag));
            }

            /*
            if (line.tag != null) {
                if (line.tag.enabled) {
                    label.parent.add_css_class (TagContext.get_style_name_for_tag (line.tag));
                } else {
                    label.parent.remove_css_class (TagContext.get_style_name_for_tag (line.tag));
                }
            } else {
                clear_all_tag_styles (label);
            } 
            */
        }
    }
}
