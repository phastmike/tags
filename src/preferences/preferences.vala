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

        /* Could use ColorScheme Classs */
        private bool _ln_visible;
        private string _ln_fg_color;
        private string _ln_bg_color;
        private bool _tags_autoload;
        private bool _minimap_visible;

        public signal void line_number_color_fg_changed (string color);
        public signal void line_number_color_bg_changed (string color);
        public signal void line_number_visibility_changed (bool visibility);
        public signal void minimap_visibility_changed (bool visibility);

        private Preferences () {
            preferences = new GLib.Settings ("io.github.phastmike.tags");

            _ln_visible = preferences.get_boolean("line-numbers-visible");
            _ln_fg_color = preferences.get_string ("line-numbers-fg-color");
            _ln_bg_color = preferences.get_string ("line-numbers-bg-color");
            _tags_autoload = preferences.get_boolean ("tags-autoload");
            _minimap_visible = preferences.get_boolean ("minimap-visible");
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

        public string ln_fg_color {
            get {
                return _ln_fg_color; 
            }

            set {
                _ln_fg_color = value;
                preferences.set_string ("line-numbers-fg-color", value);
                line_number_color_fg_changed (value);
            }
        }

        public string ln_bg_color {
            get {
                return _ln_bg_color; 
            }

            set {
                _ln_bg_color = value;
                preferences.set_string ("line-numbers-bg-color", value);
                line_number_color_bg_changed (_ln_bg_color);
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
    }

}
