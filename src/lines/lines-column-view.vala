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
        private const int _wrap_height = 18;
        private uint _wrap_nlines = 2;

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

        public LinesColumnView (GLib.ListModel model) {
            this.lines = model;
            selection_model = new Gtk.MultiSelection (model);
            column_view.set_model (selection_model);

            wrap_lines = false;
            
            // Text height Hack
            /*
            int width, height;
            var label = new Gtk.Label ("X");
            label.get_layout().get_pixel_size (out width, out height);
            _wrap_height = (height * ((int) _wrap_nlines)) + 1; 
            */

            // Hide header hack
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

            if (line.tag == null) {
                clear_all_tag_styles (label);
            } else {
                update_line_tag_style (label, line);
            }

            if (line.sighandler == 0) {
                line.sighandler = line.tag_changed.connect (() => {
                    if (label != null && line != null) {
                        if (line.tag == null) {
                            clear_all_tag_styles (label);
                        } else {
                            update_line_tag_style (label, line);
                        }
                    }
                });
            }
        }

        [GtkCallback]
        private void line_text_unbind_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            var label = listitem.child as Gtk.Label;
            var line = listitem.item as Line;

            clear_all_tag_styles (label);

            if (line.sighandler != 0) {
                line.disconnect (line.sighandler);
                line.sighandler = 0;
            }
        }

        private void clear_all_tag_styles (Gtk.Widget widget) {
            if (widget == null || widget.parent == null) {
                return;
            }
            var c = widget.parent;
            if (c.css_classes.length != 0) {
                foreach (var css_class in c.css_classes) {
                    if (css_class.has_prefix ("tag-")) {
                        c.remove_css_class (css_class);
                    }
                }
            }
        }

        private void update_line_tag_style (Gtk.Label label, Line line) { 
            if (line.tag != null) {
                if (line.tag.enabled) {
                    label.parent.add_css_class (line.actual_style);
                } else {
                    label.parent.remove_css_class (line.actual_style);
                }
            } 
        }
    }
}
