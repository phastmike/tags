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

        public bool enabled { 
            get {
                return _enabled;
            }
            set {
                _enabled = value;
                enable_changed (enabled);
            }
        }

        public uint hits { get; set; default = 0; }
        public string? pattern { get; set; } 
        public string? description { get; set; }
        public bool is_regex { get; set; default = false; }
        public bool is_case_sensitive { get; set; default = false; }
        public ColorScheme colors { get; set; }

        public signal void enable_changed (bool enabled);

        public Tag (string pattern, string description, ColorScheme colors) {
            this.pattern = pattern;
            this.description = description;
            this.colors = colors;
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
