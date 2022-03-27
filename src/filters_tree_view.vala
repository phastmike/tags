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
	[GtkTemplate (ui = "/org/ampr/ct1enq/gtat/filters_tree_view.ui")]
	public class FiltersTreeView : Gtk.TreeView {
		[GtkChild]
		unowned Gtk.ListStore filter_store;

		public FiltersTreeView (Gtk.Application app) {
            Gtk.TreeIter iter;
            string contents;
            try {
                if (FileUtils.get_contents("example.log", out contents, null)) {
                    var nr = 0;
                    var lines = contents.split ("\n");
                    /*
                    foreach (var line in lines) {
                        filter_store.append (out iter);
                        filter_store.@set (iter, 0, ++nr, 1, line);
                    }
                    */
                } else {
                    print("Error opening file [%s]\n", "example.log");
                }
            } catch (FileError err) {
                print("Error: %s\n", err.message);
            } 
        }
    }
}
