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

		public Window (Gtk.Application app) {
			Object (application: app);

            this.default_width = 640;
            this.default_height = 480;

            header_bar.set_title_widget(new Gtk.Label("Text Analysis Tool"));

            var paned = new Gtk.Paned (Gtk.Orientation.VERTICAL);
            set_child (paned);

            LinesTreeView lines_treeview = new LinesTreeView (app);

            var scrolled_lines = new Gtk.ScrolledWindow ();
            scrolled_lines.set_kinetic_scrolling (true);
            scrolled_lines.set_placement (Gtk.CornerType.TOP_LEFT);
            scrolled_lines.set_overlay_scrolling (true);
            scrolled_lines.set_child (lines_treeview);

            var scrolled_filters = new Gtk.ScrolledWindow ();
            scrolled_filters.set_kinetic_scrolling (true);
            scrolled_filters.set_placement (Gtk.CornerType.TOP_LEFT);
            scrolled_filters.set_overlay_scrolling (true);
            scrolled_filters.set_child (new FiltersTreeView (app));

            paned.set_start_child (scrolled_lines);
            paned.set_end_child (scrolled_filters);
            paned.set_resize_start_child (true);
            paned.set_resize_end_child (true);
            paned.set_position (360);
            paned.set_wide_handle (true);

            button_open_file.clicked.connect (() => {
                var file_chooser_dialog = new Gtk.FileChooserDialog ("Open File", this, Gtk.FileChooserAction.OPEN, "Open", Gtk.ResponseType.ACCEPT, "Cancel", Gtk.ResponseType.CANCEL, null);
                file_chooser_dialog.set_modal (true);
                file_chooser_dialog.response.connect ( (response_id) => {
                    if (response_id == Gtk.ResponseType.ACCEPT) {
                        print ("Should open file: \n");
                        lines_treeview.set_file(file_chooser_dialog.get_file ().get_path ());
                    }
                    file_chooser_dialog.destroy ();
                });
                file_chooser_dialog.show ();
            });
		}
	}
}
