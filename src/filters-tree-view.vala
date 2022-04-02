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
	[GtkTemplate (ui = "/org/ampr/ct1enq/gtat/filters-tree-view.ui")]
	public class FiltersTreeView : Gtk.TreeView {
		[GtkChild]
		private unowned Gtk.ListStore filter_store;
		[GtkChild]
        private unowned Gtk.TreeViewColumn col_filter_checkbox;
		[GtkChild]
        private unowned Gtk.TreeViewColumn col_filter_pattern;
		[GtkChild]
        private unowned Gtk.TreeViewColumn col_filter_description;
		[GtkChild]
        private unowned Gtk.TreeViewColumn col_filter_hits;
		[GtkChild]
        private unowned Gtk.CellRendererToggle renderer_filter_checkbox;
		[GtkChild]
        private unowned Gtk.CellRendererText renderer_filter_pattern;
		[GtkChild]
        private unowned Gtk.CellRendererText renderer_filter_description;
		[GtkChild]
        private unowned Gtk.CellRendererText renderer_filter_hits;

		public FiltersTreeView (Gtk.Application app) {
            setup_cell_renderers ();
            
            renderer_filter_checkbox.toggled.connect ((path) => {
                Gtk.TreeIter i;
                LineFilter filter;
                filter_store.get_iter_from_string (out i, path);
                filter_store.@get (i, 0, out filter);
                filter.enabled = !filter.enabled;
            });
        }
        
        private void setup_cell_renderers () {
            col_filter_checkbox.set_cell_data_func (renderer_filter_checkbox, (column, cell, model, iter) => {
                LineFilter filter;
                model.@get (iter, 0, out filter);
                (cell as Gtk.CellRendererToggle?).set_active (filter.enabled);
            });
            
            col_filter_pattern.set_cell_data_func (renderer_filter_pattern, (column, cell, model, iter) => {
                LineFilter filter;
                model.@get (iter, 0, out filter);
                (cell as Gtk.CellRendererText).text = filter.pattern != null ? filter.pattern : "";
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
            });

            col_filter_description.set_cell_data_func (renderer_filter_description, (column, cell, model, iter) => {
                LineFilter filter;
                model.@get (iter, 0, out filter);
                (cell as Gtk.CellRendererText).text = filter.description != null ? filter.description : "";
            });

            col_filter_hits.set_cell_data_func (renderer_filter_hits, (column, cell, model, iter) => {
                LineFilter filter;
                model.@get (iter, 0, out filter);
                (cell as Gtk.CellRendererText).text = "%u".printf(filter.hits);
            });
            
        }

        public void add_filter (LineFilter filter) {
            Gtk.TreeIter iter;
            filter_store.append (out iter);
            filter_store.@set (iter, 0, filter);
        }

    }
}
