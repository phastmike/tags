/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * application.vala
 *
 * Application Class
 *
 * José Miguel Fonte
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
            string[] authors = {
                "Jose Miguel Fonte"
            };

            string[] artists = {
                "MD Badsha Meah on freeicons.io (App Icon)",
                "www.wishforge.games on freeicons.io (Symbolic Icon)"
            };

            Gtk.show_about_dialog(this.active_window,
                                  "program-name", "Tagger",
                                  "authors", authors,
                                  "artists", artists,
                                  "title", "About Tagger",
                                  "license-type", Gtk.License.MIT_X11,
                                  "wrap-license", true,
                                  "comments", "Tag lines to a given color scheme.\nPaint for logs ftw!",
                                  "logo-icon-name", "org.ampr.ct1enq.gtat",
                                  "website", "https://github.com/phastmike/tagger",
                                  "website-label", "https://github.com/phastmike/tagger",
                                  "version", "0.1.0");
        }

        private void on_preferences_action () {
            message("app.preferences action activated");
            new PreferencesWindow (this);
        }
    }
}
