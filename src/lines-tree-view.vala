/* tree_view_main.vala
 *
 * Copyright 2022 Jose Miguel Fonte
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE X CONSORTIUM BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * Except as contained in this notice, the name(s) of the above copyright
 * holders shall not be used in advertising or otherwise to promote the sale,
 * use or other dealings in this Software without prior written
 * authorization.
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

        public bool hide_untagged;

		public LinesTreeView (Gtk.Application app) {
            hide_untagged = false;

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
                model.@get (iter, 2, out filter);
                if (filter != null) {
                    if (filter.colors.fg != null) {
                        (cell as Gtk.CellRendererText).foreground_rgba = filter.colors.fg;
                    } else {
                        (cell as Gtk.CellRendererText).foreground = null;
                    }
                    if (filter.colors.bg != null) {
                        (cell as Gtk.CellRendererText).background_rgba = filter.colors.bg;
                    } else {
                        (cell as Gtk.CellRendererText).background = null;
                    }
                } else {
                    (cell as Gtk.CellRendererText).foreground = null;
                    (cell as Gtk.CellRendererText).background = null;
                }
            });
        }

        public void set_file (string file) {
            Gtk.TreeIter iter;
            string contents;

            line_store.clear ();

            try {
                if (FileUtils.get_contents(file, out contents, null)) {
                    var nr = 0;
                    var lines = contents.split ("\n");
                    lines.resize (lines.length - 1);
                    foreach (var line in lines) {
                        line_store.append (out iter);
                        line_store.@set (iter, 0, ++nr, 1, line, 2, null, -1);
                    }
                } else {
                    print("Error opening file [%s]\n", "example.log");
                }
            } catch (FileError err) {
                print("Error: %s\n", err.message);
            } 
        }

        public void tag_lines (Gtk.ListStore filters) {
            /* Clear Filter Hit Counter */
            filters.foreach ((filters_model, filter_path, filter_iter) => {
                LineFilter filter;
                filters_model.@get (filter_iter, 0, out filter);
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
                    if (filter.enabled == false) return false; 
                    if (line.contains (filter.pattern)) {
                        line_store.@set (lines_iter, 2, filter);
                        filter.hits += 1;
                        return true;
                    } else {
                        return false;
                    }
                });
                return false;
            });
        }
    }
}
