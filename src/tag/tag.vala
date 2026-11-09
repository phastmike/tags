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

        private bool    _enabled            = true;
        private string? _pattern            = null;
        private string? _description        = null;
        private bool    _is_regex           = false;
        private bool    _is_case_sensitive  = false;

        public string       uuid    { get; private set; }
        public ColorScheme  colors  { get; set; }

        public bool enabled { 
            get {
                return _enabled;
            }
            set {
                if (_enabled == value) return;
                _enabled = value;
                enabled_changed (enabled);
            }
        }

        public string? pattern {
            get {
                return _pattern;
            }
            set {
                if (_pattern == value) return;
                _pattern = value;
                changed ();
            }
        }

        public string? description {
            get {
                return _description;
            }
            set {
                if (_description == value) return;
                _description = value;
                //changed ();
            }
        }

        public bool is_regex {
            get {
                return _is_regex;
            }
            set {
                if (_is_regex == value) return;
                _is_regex = value;
                changed ();
            }
        }

        public bool is_case_sensitive {
            get {
                return _is_case_sensitive;
            }
            set {
                if (_is_case_sensitive == value) return;
                _is_case_sensitive = value;
                changed ();
            }
        }

        /* SIGNALS */

        public signal void changed ();
        public signal void enabled_changed (bool enabled);
        public signal void to_be_deleted ();

        /* CONSTRUCTORS */

        construct {
            _enabled = false;
            uuid = Tags.Common.generate_uuid ();
        }

        public Tag (TagBuilder builder) {
            _pattern = builder.pattern;
            _description = builder.description;
            _enabled = builder.enabled;
            _is_regex = builder.is_regex;
            _is_case_sensitive = builder.is_case_sensitive;

            this.colors = builder.colors;

            this.colors.changed.connect (() => {
                changed ();
            });
        }

        /* METHODS */

        public bool matches (string? text = null) {
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

        public void dump_to_console () {
            stdout.printf ("Tag:\n");
            stdout.printf ("  Pattern:  %s\n", this.pattern);
            stdout.printf ("  Description: %s\n", this.description);
            stdout.printf ("  Enabled: %s\n", this.enabled ? "true" : "false");
            stdout.printf ("  Is Regex: %s\n", this.is_regex ? "true" : "false");
            stdout.printf ("  Is Case Sensitive: %s\n", this.is_case_sensitive ? "true" : "false");
            stdout.printf ("  Colors:\n");
            stdout.printf ("    Foreground: %s\n", this.colors.fg != null ? this.colors.fg.to_string () : "null");
            stdout.printf ("    Background: %s\n", this.colors.bg != null ?  this.colors.bg.to_string () : "null");
        }
    }
}
