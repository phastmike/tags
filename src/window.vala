/* window.vala
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
	[GtkTemplate (ui = "/org/ampr/ct1enq/gtat/window.ui")]
	public class Window : Gtk.ApplicationWindow {
        [GtkChild]
        unowned Gtk.HeaderBar header_bar;
        [GtkChild]
        unowned Gtk.Button button_open_file;
        [GtkChild]
        unowned Gtk.Button button_tags;
        
        private Gtk.Paned paned;
        private LinesTreeView lines_treeview;
        private FiltersTreeView filters_treeview;

        private int paned_last_position = -1;

		private ActionEntry[] WINDOW_ACTIONS = {
			{ "add_tag", add_tag },
			{ "hide_untagged_lines", hide_untagged_lines },
			{ "toggle_filters_view", toggle_filters_view }
		};

		public Window (Gtk.Application app) {
			Object (application: app);

			this.add_action_entries(this.WINDOW_ACTIONS, this);
			app.set_accels_for_action("win.add_tag", {"<primary>n"});
			app.set_accels_for_action("win.hide_untagged_lines", {"<primary>h"});
			app.set_accels_for_action("win.toggle_filters_view", {"<primary>f"});
            
            lines_treeview = new LinesTreeView (app);
            filters_treeview = new FiltersTreeView (app);
            
            lines_treeview.row_activated.connect ((path, column) => {
                string line_text;
                Gtk.TreeIter iter;
                LineFilter line_filter;
                FilterDialogWindow filter_dialog;

                lines_treeview.get_selection ().get_selected (null, out iter);
                lines_treeview.get_model ().@get (iter, 1, out line_text, 2, out line_filter);

                if (line_filter != null) {
                    filter_dialog = new FilterDialogWindow.for_editing (app, line_filter);
                    filter_dialog.added.connect ((filter) => {
                        lines_treeview.tag_lines (filters_treeview.get_model () as Gtk.ListStore);
                    });
                } else {
                    filter_dialog = new FilterDialogWindow (app, line_text);
                    filter_dialog.added.connect ((filter) => {
                        filters_treeview.add_filter (filter);
                        lines_treeview.tag_lines (filters_treeview.get_model () as Gtk.ListStore);
                    });
                }

                filter_dialog.show ();
            });


            filters_treeview.row_activated.connect ((path, column) => {
                LineFilter filter;
                Gtk.TreeIter iter;

                filters_treeview.get_selection ().get_selected (null, out iter);

                filters_treeview.get_model ().@get (iter, 0, out filter);
                var filter_dialog = new FilterDialogWindow.for_editing (app, filter);
                filter_dialog.show ();
                filter_dialog.added.connect ((filter) => {
                    filters_treeview.queue_draw ();
                    lines_treeview.tag_lines (filters_treeview.get_model () as Gtk.ListStore);
                });
                
                filter_dialog.deleted.connect ((filter) => {
                    filters_treeview.get_model ().foreach ((model, path, iter) => {
                        LineFilter lf;
                        model.@get (iter, 0, out lf);
                        if (lf == filter) {
                            (model as Gtk.ListStore).remove (ref iter);
                            return true;
                        } else {
                            return false;
                        }
                    });
                    lines_treeview.tag_lines (filters_treeview.get_model () as Gtk.ListStore);
                });
            });

            paned = new Gtk.Paned (Gtk.Orientation.VERTICAL);
            set_child (paned);

            var scrolled_lines = new Gtk.ScrolledWindow ();
            scrolled_lines.set_kinetic_scrolling (true);
            scrolled_lines.set_placement (Gtk.CornerType.TOP_LEFT);
            scrolled_lines.set_overlay_scrolling (true);
            scrolled_lines.set_child (lines_treeview);

            var scrolled_filters = new Gtk.ScrolledWindow ();
            scrolled_filters.set_kinetic_scrolling (true);
            scrolled_filters.set_placement (Gtk.CornerType.TOP_LEFT);
            scrolled_filters.set_overlay_scrolling (true);
            scrolled_filters.set_child (filters_treeview);

            paned.set_start_child (scrolled_lines);
            paned.set_end_child (scrolled_filters);
            paned.set_resize_start_child (true);
            paned.set_resize_end_child (true);
            paned.set_wide_handle (true);
            paned.set_position (this.default_height - 47 - 160);
            paned.queue_draw ();

            button_open_file.clicked.connect ( () => {
                var file_chooser_dialog = new Gtk.FileChooserDialog (
                    "Open File", this, Gtk.FileChooserAction.OPEN, 
                    "Open", Gtk.ResponseType.ACCEPT, 
                    "Cancel", Gtk.ResponseType.CANCEL, 
                    null);
                file_chooser_dialog.set_modal (true);
                file_chooser_dialog.response.connect ( (response_id) => {
                    if (response_id == Gtk.ResponseType.ACCEPT) {
                        lines_treeview.set_file(file_chooser_dialog.get_file ().get_path ());
                        lines_treeview.tag_lines (filters_treeview.get_model () as Gtk.ListStore);
                    }
                    file_chooser_dialog.destroy ();
                });
                file_chooser_dialog.show ();
            });

            button_tags.clicked.connect ( () => {
                add_tag ();
            });
		}

		private void add_tag () {
            var filter_dialog_window = new FilterDialogWindow (this.application);
            filter_dialog_window.show ();

            filter_dialog_window.added.connect ((filter) => {

                filters_treeview.add_filter (filter);

                filter.enable_changed.connect ((enabled) => {
                    lines_treeview.line_store_filter.refilter ();
                    lines_treeview.tag_lines (filters_treeview.get_model () as Gtk.ListStore);
                });

                lines_treeview.tag_lines (filters_treeview.get_model () as Gtk.ListStore);
            });
		}

		private void hide_untagged_lines () {
            lines_treeview.hide_untagged = !lines_treeview.hide_untagged; 
            lines_treeview.line_store_filter.refilter ();
            lines_treeview.tag_lines (filters_treeview.get_model () as Gtk.ListStore);
		}

        private void toggle_filters_view () {
            var view_height = paned.get_allocated_height ();
            //paned.set_position (paned.get_position () >= view_height - 5 ? view_height - 160 : view_height - 5);

            if (paned.get_position () >= view_height - 5) {
                paned.set_position (paned_last_position);
            } else {
                paned_last_position = paned.get_position ();
                paned.set_position (view_height - 5);
            }
        }
	}
}
