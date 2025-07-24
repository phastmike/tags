/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * lines-tree-view.vala
 *
 * Extended Treeview for LinesTreeview
 *
 * José Miguel Fonte
 */

namespace Tags {
    [GtkTemplate (ui = "/io/github/phastmike/tags/lines-tree-view.ui")]
    public class LinesTreeView : Gtk.TreeView {
        [GtkChild]
        unowned Gtk.ListStore line_store;
        [GtkChild]
        public unowned Gtk.TreeModelFilter line_store_filter;
        [GtkChild]
        public unowned Gtk.TreeViewColumn col_line_number;
        [GtkChild]
        unowned Gtk.TreeViewColumn col_line_text;
        [GtkChild]
        unowned Gtk.CellRendererText renderer_line_text;
        [GtkChild]
        unowned Gtk.CellRendererText renderer_line_number;

        public enum Columns {
            LINE_NUMBER,
            LINE_TEXT;
        }

        private Gtk.TreeModel tags;
        public bool hide_untagged {set; get; default=false;}
        private bool will_clear_all {private set; private get; default=false;}

        public signal void set_file_ended ();

        public LinesTreeView (Gtk.Application app, Gtk.TreeModel tags) {
            var preferences = Preferences.instance ();

            update_line_number_colors (preferences);

            this.tags = tags;
            this.model = line_store_filter;
            col_line_number.set_visible (preferences.ln_visible);

            preferences.line_number_colors_changed.connect ((p) => {
                update_line_number_colors (p);
                col_line_number.set_visible (p.ln_visible);
            });

            this.set_search_equal_func ((model, column, key, iter) => {
                string line;
                model.@get (iter, Columns.LINE_TEXT, out line);
                return !line.contains(key);
            });

            line_store_filter.set_visible_func ((model, iter) => {
                if (will_clear_all == true) {
                    return false;
                }

                if (hide_untagged == false) {
                    return true;
                } else {
                    string line;
                    bool found = false;

                    model.@get (iter, 1, out line);
                    tags.foreach ((tags_model, tag_path, tag_iter) => {
                        Tag tag;

                        tags_model.@get (tag_iter, 0, out tag);
                        
                        if (tag.applies_to (line) && tag.enabled) {
                            found = true;
                        } 
                        
                        return found; 
                    });
                    return found ? true : false;
                }
            });

            col_line_text.set_cell_data_func (renderer_line_text, (column, cell, model, iter) => {
                Tag? tag = null;

                var cell_text = (Gtk.CellRendererText) cell; 

                bool found = false;

                tags.foreach ((tags_model, tag_path, tag_iter) => {

                    tags_model.@get (tag_iter, 0, out tag);
                    
                    if (tag.applies_to (renderer_line_text.text) && tag.enabled) {
                        found = true;
                    }
                    return found;
                });

                if (found) {
                    if (tag.colors.fg != null) {
                        cell_text.foreground_rgba = tag.colors.fg;
                    } else {
                        cell_text.foreground = null;
                    }
                    if (tag.colors.bg != null) {
                        cell_text.background_rgba = tag.colors.bg;
                    } else {
                        cell_text.background = null;
                    }
                } else {
                    cell_text.foreground = null;
                    cell_text.background = null;
                }
            });
        }

        public string get_selected_lines_as_string () {
            var string_builder = new StringBuilder ();
            var selection = get_selection ();
            selection.selected_foreach ((model, path, iter) => {
                string line_text;
                model.@get (iter, LinesTreeView.Columns.LINE_TEXT, out line_text);
                string_builder.append (line_text + "\n");
            });
            
            return (string) string_builder.data;
        }

        /* Helper method to aid in the async read from the input stream */
        private async void read_from_input_stream_async (DataInputStream dis) {
            var nr = 0;
            string? line;
            Gtk.TreeIter iter;

            try {
                while ((line = yield dis.read_line_async ()) != null) {
                    //line = line.escape ();
                    if (line.data[line.length-1] == '\r') {
                        line.data[line.length-1] = ' ';
                    }
                    line_store.append (out iter);
                    line_store.@set (iter, Columns.LINE_NUMBER, ++nr, Columns.LINE_TEXT, line, -1);
                }
            } catch (IOError e) {
                warning ("%s/n", e.message);
            }
        }

        public void set_file (File file, Cancellable cancellable) {
            this.model = null;

            // Workaround to speed up removing lines
            will_clear_all = true;
            line_store_filter.refilter ();
            line_store.clear ();
            will_clear_all = false;

            file.read_async.begin (Priority.DEFAULT, cancellable, (obj, res) => {
                Gtk.TreeIter iter;
                try {
                    FileInputStream @is = file.read_async.end (res);
                    DataInputStream dis = new DataInputStream (@is);
                    read_from_input_stream_async.begin (dis, (obj, res) => {
                        set_file_ended();
                    });
                } catch (Error e) {
                    warning (e.message);
                }
            });

            this.model = line_store_filter;
        }

        public async void to_file (File file) {
            StringBuilder str;
            FileOutputStream fsout;

            str = new StringBuilder ();
            str.append("");     // Fixes minor bug? Buffer isn't empty !?!?

            line_store_filter.foreach ((model, path, iter) => {
                string line;
                model.@get (iter, Columns.LINE_TEXT, out line);
                str.append_printf ("%s\n", line);
                return false;
            });

            try {
                fsout = file.replace (null, false, FileCreateFlags.REPLACE_DESTINATION, null); 
                fsout.write_all_async.begin (str.data, Priority.DEFAULT, null, (obj, res) => {
                    fsout.close ();
                });
            } catch (Error e) {
                warning ("Error: %s", e.message);
            }
        }

        private void update_line_number_colors (Preferences p) {
            var rgb = Gdk.RGBA ();

            rgb.parse (p.ln_fg_color);
            renderer_line_number.foreground_rgba = rgb;
            rgb.parse (p.ln_bg_color);
            renderer_line_number.background_rgba = rgb;
            //renderer_line_number.size_points = 8.0;
            
            queue_draw ();
        }

        public int get_number_of_items () {
            return model.iter_n_children (null);
        }
    }
}
