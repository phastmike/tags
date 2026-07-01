/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * preferences.vala
 *
 * Application preferences singleton
 *
 * José Miguel Fonte
 */

namespace Tags {
    public class Preferences : Object {
        private GLib.Settings preferences;
        private static Once<Preferences> _instance;

        private bool _ln_visible;
        private bool _tags_autoload;
        private bool _minimap_visible;
        private uint _wrap_nlines;

        public signal void line_number_visibility_changed (bool visibility);
        public signal void minimap_visibility_changed (bool visibility);

        private Preferences () {
            preferences = new GLib.Settings ("io.github.phastmike.tags");

            _ln_visible = preferences.get_boolean("line-numbers-visible");
            _tags_autoload = preferences.get_boolean ("tags-autoload");
            _minimap_visible = preferences.get_boolean ("minimap-visible");
            _wrap_nlines = preferences.get_uint ("wrap-nlines");
        }

        public static unowned Preferences instance () {
            return _instance.once (() => {
                return new Preferences ();
            });
        }

        public bool ln_visible {
            get {
                return _ln_visible;
            }

            set {
                _ln_visible = value;
                preferences.set_boolean ("line-numbers-visible", value);
                line_number_visibility_changed (value);
            }
        }

        public bool tags_autoload {
            get {
                return _tags_autoload;
            }

            set {
                _tags_autoload = value;
                preferences.set_boolean ("tags-autoload", value);
            }
        }

        public bool minimap_visible {
            get {
                return _minimap_visible;
            }

            set {
                _minimap_visible = value;
                preferences.set_boolean ("minimap-visible", value);
                minimap_visibility_changed (value);
            }
        }

        public uint wrap_nlines {
            get {
                return _wrap_nlines;
            }

            set {
                if (value > 0 && value < 11) {
                    _wrap_nlines = value;
                    preferences.set_uint ("wrap-nlines", value);
                }
            }
        }
    }

}
