/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * lines-tree-view.vala
 *
 * Extended Treeview for LinesTreeview
 *
 * José Miguel Fonte
 */

namespace Gtat {
    [GtkTemplate (ui = "/org/ampr/ct1enq/gtat/lines-tree-view.ui")]
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

        public bool hide_untagged {set; get; default=false;}

        public LinesTreeView (Gtk.Application app) {
            var preferences = Preferences.instance ();

            update_line_number_colors (preferences);

            preferences.line_number_colors_changed.connect ((p) => {
                update_line_number_colors (p);
            });

            this.set_search_equal_func ((model, column, key, iter) => {
                string line;
                model.@get (iter, 1, out line);
                return !line.contains(key);
            });

            line_store_filter.set_visible_func ((model, iter) => {
                if (hide_untagged == false) {
                    return true;
                } else {
                    LineFilter? filter; 
                    model.@get (iter, 2, out filter);
                    if (filter != null) {
                        return true;
                    } else {
                        return false;
                    }
                }
            });

            this.model = line_store_filter;

            col_line_text.set_cell_data_func (renderer_line_text, (column, cell, model, iter) => {
                LineFilter filter;
                var cell_text = (Gtk.CellRendererText) cell; 

                model.@get (iter, 2, out filter);
                if (filter != null) {
                    if (filter.colors.fg != null) {
                        cell_text.foreground_rgba = filter.colors.fg;
                    } else {
                        cell_text.foreground = null;
                    }
                    if (filter.colors.bg != null) {
                        cell_text.background_rgba = filter.colors.bg;
                    } else {
                        cell_text.background = null;
                    }
                } else {
                    cell_text.foreground = null;
                    cell_text.background = null;
                }
            });
        }

        public void set_file (string file) {
            uint8[] con;
            Gtk.TreeIter iter;
            string? contents;

            line_store.clear ();

            try {
                if (FileUtils.get_data(file, out con)) {
                    for (int i = 0; i < con.length - 2; i++) {
                        /* change nulls for '0' */
                        if (con[i] == 0x00) {
                            con[i] = 0x30;
                        }
                    }
                    contents = (string) con;
                    var nr = 0;
                    var lines = contents.split ("\n");
                    lines.resize (lines.length - 1);
                    foreach (unowned var line in lines ) {
                        line_store.append (out iter);
                        line_store.@set (iter, 0, ++nr, 1, line, 2, null, -1);
                    }
                } else {
                    warning ("Error opening file [%s]\n", file);
                }
            } catch (FileError err) {
                warning ("Error: %s\n", err.message);
            }
        }

        public void set_file2 (string file) {
            Gtk.TreeIter iter;
            string? contents;

            line_store.clear ();

            try {
                if (FileUtils.get_contents(file, out contents, null)) {
                    var nr = 0;
                    var lines = contents.split ("\n");
                    lines.resize (lines.length - 1);
                    foreach (var line in lines ) {
                        line_store.append (out iter);
                        line_store.@set (iter, 0, ++nr, 1, line, 2, null, -1);
                    }
                } else {
                    warning ("Error opening file [%s]\n", file);
                }
            } catch (FileError err) {
                warning ("Error: %s\n", err.message);
            }
        }

        public void tag_lines (Gtk.ListStore filters) {
            /* Clear Filter Hit Counter */
            filters.foreach ((filters_model, filter_path, filter_iter) => {
                LineFilter filter;
                filters_model.@get (filter_iter, 0, out filter);
                message ("Reseting hits [%s]\n", filter.description);
                filter.hits = 0;
                return false;
            });

            line_store.foreach ((lines_model, lines_path, lines_iter) => {
                string line;

                lines_model.@get (lines_iter, 1, out line);
                line_store.@set (lines_iter, 2, null);

                filters.foreach ((filters_model, filter_path, filter_iter) => {
                    LineFilter filter;

                    filters_model.@get (filter_iter, 0, out filter);

                    if (filter.enabled == false) {
                        return false;
                    }

                    if (line.contains (filter.pattern)) {
                        line_store.@set (lines_iter, 2, filter);
                        filter.hits += 1;
                        return true;
                    } else {
                        return false;
                    }
                });

                queue_draw ();
                return false;
            });
        }

        public void update_line_number_colors (Preferences p) {
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
