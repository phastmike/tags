/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * lines-tree-view.vala
 *
 * Extended Treeview for LinesTreeview
 *
 * José Miguel Fonte
 */

namespace Tagger {
    [GtkTemplate (ui = "/org/ampr/ct1enq/tagger/lines-tree-view.ui")]
    public class LinesTreeView : Gtk.TreeView {
        [GtkChild]
        unowned Gtk.ListStore line_store;
        [GtkChild]
        public unowned Gtk.TreeModelFilter line_store_filter;
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

        public LinesTreeView (Gtk.Application app, Gtk.TreeModel tags) {
            var preferences = Preferences.instance ();

            update_line_number_colors (preferences);

            this.tags = tags;

            preferences.line_number_colors_changed.connect ((p) => {
                update_line_number_colors (p);
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
                        
                        Regex regex = new Regex (tag.pattern);
                        if (regex.match (line) == true && tag.enabled) {
                        //if (line.contains (tag.pattern) && tag.enabled == true) {
                            found = true;
                            return true;
                        } else {
                            return false;
                        }
                    });

                    return found ? true : false;
                }
            });

            this.model = line_store_filter;

            col_line_text.set_cell_data_func (renderer_line_text, (column, cell, model, iter) => {
                Tag? tag = null;

                var cell_text = (Gtk.CellRendererText) cell; 

                bool found = false;

                tags.foreach ((tags_model, tag_path, tag_iter) => {

                    tags_model.@get (tag_iter, 0, out tag);
                    
                    Regex regex = new Regex (tag.pattern);
                    if (regex.match (renderer_line_text.text) == true && tag.enabled) {
                    //if (renderer_line_text.text.contains (tag.pattern) && tag.enabled == true) {
                        found = true;
                        return true;
                    } else {
                        return false;
                    }
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

        public void set_file (string file) {
            uint8[] con;
            string? contents;
            Gtk.TreeIter iter;

            this.model = null;

            // Workaround to speed up removing lines
            will_clear_all = true;
            line_store_filter.refilter ();
            line_store.clear ();
            will_clear_all = false;

            try {
                if (FileUtils.get_data(file, out con)) {
                    /* FIXME: 
                       Simple fix to solve problematic text files with CR+LF problems
                       We are spliting \r\n because some files only have \r (CR)
                    */
                    for (int i = 0; i < con.length - 2; i++) {
                        if (con[i] == 0x00) {
                            con[i] = 0x30;
                        } else if (con[i] == '\r' && con[i+1] == '\n') {
                            con[i] = ' ';
                        }
                    }
                    contents = (string) con;
                    var nr = 0;
                    var lines = contents.split_set("\r\n");
                    lines.resize (lines.length - 1);
                    foreach (unowned var line in lines ) {
                        line_store.append (out iter);
                        line_store.@set (iter, Columns.LINE_NUMBER, ++nr, Columns.LINE_TEXT, line, -1);
                    }
                } else {
                    warning ("Error opening file [%s]\n", file);
                }
            } catch (FileError err) {
                warning ("Error: %s\n", err.message);
            }

            this.model = line_store_filter;
        }

        public void to_file (File file) {
            FileOutputStream fsout;
            try {
                fsout = file.replace (null, false, FileCreateFlags.REPLACE_DESTINATION, null); 
                line_store_filter.foreach ((model, path, iter) => {
                    string line;
                    model.@get (iter, Columns.LINE_TEXT, out line);
                    fsout.write(("%s\n".printf (line)).data);
                    return false;
                });
                fsout.close ();
            } catch (Error e) {
                error ("Error: %s", e.message);
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
    }
}
