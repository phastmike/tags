/* application.vala
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
	public class Application : Gtk.Application {
		private ActionEntry[] APP_ACTIONS = {
			{ "about", on_about_action },
			{ "preferences", on_preferences_action },
			{ "quit", quit }
		};


		public Application () {
			Object (application_id: "org.ampr.ct1enq.gtat", flags: ApplicationFlags.FLAGS_NONE);

			this.add_action_entries(this.APP_ACTIONS, this);
			this.set_accels_for_action("app.quit", {"<primary>q"});
		}

		public override void activate () {
			base.activate();
			var win = this.active_window;
			if (win == null) {
				win = new Gtat.Window (this);
			}
			win.present ();
		}

		private void on_about_action () {
			string[] authors = {"Jose Miguel Fonte"};
			Gtk.show_about_dialog(this.active_window,
				                  "program-name", "gtat",
				                  "authors", authors,
				                  "version", "0.1.0");
		}

		private void on_preferences_action () {
			message("app.preferences action activated");
		}
	}
}
