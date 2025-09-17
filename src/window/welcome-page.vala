/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * welcome-page.vala
 *
 * Landing page view. To be used in a GtkStack on startup.
 *
 * José Miguel Fonte
 */

namespace Tags {
    [GtkTemplate (ui = "/io/github/phastmike/tags/ui/welcome-page.ui")]
    public class WelcomePage : Gtk.Box {
    
        public WelcomePage () {

        }
    }
}
