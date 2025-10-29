/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * tag.vala
 *
 * Class containing a Tag 
 *
 * José Miguel Fonte
 */

namespace Tags {

    public class Tag : Object {
        private bool _enabled = true;
        private string? _pattern = null;
        private string? _description = null;
        private bool _is_regex = false;
        private bool _is_case_sensitive = false;

        public bool enabled { 
            get {
                return _enabled;
            }
            set {
                _enabled = value;
                changed ();
                enable_changed (enabled);
            }
        }

        public string? pattern {
            get {
                return _pattern;
            }
            set {
                _pattern = value;
                changed ();
            }
        }

        public string? description{
            get {
                return _description;
            }
            set {
                _description = value;
                changed ();
            }
        } 

        public bool is_regex {
            get {
                return _is_regex;
            }
            set {
                _is_regex = value;
                changed ();
            }
        }

        public bool is_case_sensitive {
            get {
                return _is_case_sensitive;
            }
            set {
                _is_case_sensitive = value;
                changed ();
            }
        }

        public ColorScheme colors { get; set; }

        public uint hits { get; set; default = 0; } // Should decouple the counter

        /* SIGNALS */

        public signal void changed ();
        public signal void enable_changed (bool enabled);

        /* METHODS */

        public Tag (string pattern, string description, ColorScheme colors) {
            _pattern = pattern;
            _description = description;
            _is_regex = false;
            _is_case_sensitive = false;

            this.colors = colors;

            this.colors.name = Tags.Helpers.generate_uuid ();

            this.colors.changed.connect (() => {
                changed ();
            });
        }

        public bool applies_to (string? text = null) {
            if (text == null) return false;

            if (this.is_regex) {
                try {
                    var regex = new Regex (this.pattern, is_case_sensitive ? 0 : RegexCompileFlags.CASELESS);
                    return regex.match (text);
                } catch (RegexError e) {
                    warning ("RegexError: %s", e.message);
                    return false;
                }
            } else {
                return is_case_sensitive ? text.contains (pattern) : text.up ().contains (pattern.up ());
            }
        }
    }
}
