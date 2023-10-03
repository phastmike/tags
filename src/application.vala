/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * application.vala
 *
 * Application Class
 *
 * José Miguel Fonte
 */

namespace Tags {
    //public class Application : Gtk.Application {
    public class Application : Adw.Application {
        private ActionEntry[] APP_ACTIONS = {
            { "new_window", on_new_window },
            { "preferences", on_preferences_action },
            { "about", on_about_action },
            { "quit", quit }
        };

        public Application () {
            Object (application_id: "org.ampr.ct1enq.tags", flags: ApplicationFlags.HANDLES_OPEN);

            this.add_action_entries (this.APP_ACTIONS, this);
            this.set_accels_for_action ("app.quit", {"<primary>q"});
        }

        public override void activate () {
            base.activate ();
            var win = this.active_window;
            if (win == null) {
                win = new Tags.Window (this);
            }
            win.present ();
        }

        public override void open (File[] files, string hint) {
            foreach (var file in files) {
                if (file.query_exists () == true) {
                    var win = new Tags.Window (this);
                    win.present ();
                    win.set_file (file);
                } else {
                    warning ("file '%s' does not exist ...", file.get_basename ());
                }
            }
        }

        /**************************
            Application Actions
        **************************/

        private void on_about_action () {
            string[] authors = {
                "Jose Miguel Fonte"
            };

            string[] artists = {
                "José Miguel Fonte",
                "App icon by MD Badsha Meah on freeicons.io",
                "Symbolic icon by www.wishforge.games on freeicons.io"
            };

            Adw.show_about_window (this.active_window,
                                  "application-name", "Tags",
                                  "developer-name", "José Miguel Fonte",
                                  "developers", authors,
                                  "artists", artists,
                                  "license-type", Gtk.License.MIT_X11,
                                  "application-icon", "org.ampr.ct1enq.tags",
                                  "website", "https://github.com/phastmike/tagger",
                                  "issue-url", "https://github.com/phastmike/tagger/issues",
                                  "version", "0.9.31");
        }

        private void on_preferences_action () {
            new PreferencesWindow (this).present ();
        }

        private void on_new_window () {
            new Tags.Window (this).present ();
        }
    }
}
