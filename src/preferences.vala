/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * preferences.vala
 *
 * Application preferences singleton
 *
 * José Miguel Fonte
 */

namespace Gtat {
    public class Preferences : Object {
        private GLib.Settings preferences;
        private static Once<Preferences> _instance;

        /* Could use ColorScheme Classs */
        private string _ln_fg_color;
        private string _ln_bg_color;

        private Preferences () {
            preferences = new GLib.Settings ("org.ampr.ct1enq.gtat");

            _ln_fg_color = preferences.get_string ("line-numbers-fg-color");
            _ln_bg_color = preferences.get_string ("line-numbers-bg-color");
            message("Preferences instance, fg: %s bg: %s", _ln_fg_color, _ln_bg_color);
        }

        public static unowned Preferences instance () {
            return _instance.once (() => {
                return new Preferences ();
            });
        }

        public string ln_fg_color {
            get {
                return _ln_fg_color; 
            }

            set {
                _ln_fg_color = value;
                preferences.set_string ("line-numbers-fg-color", value);
                message("Setting preference line-numbers-foreground-color: %s", value);
            }
        }

        public string ln_bg_color {
            get {
                return _ln_bg_color; 
            }

            set {
                _ln_bg_color = value;
                
                preferences.set_string ("line-numbers-bg-color", value);
                message("Setting preference line-numbers-background-color: %s", value);
            }
        }
    }

}
