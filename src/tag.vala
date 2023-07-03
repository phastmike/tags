/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * tag.vala
 *
 * Class containing a Tag 
 *
 * José Miguel Fonte
 */

namespace Tagger {

    public class Tag : Object {
        private bool _enabled;

        public bool enabled { 
            get {
                return _enabled;
            }
            set {
                _enabled = value;
                enable_changed (enabled);
            }
        }

        public uint hits; 
        public string pattern { get; set; } 
        public string description { get; set; }
        public bool is_regex { get; set; }
        public bool is_case_sensitive { get; set; }
        public ColorScheme colors { get; set; }

        public signal void enable_changed (bool enabled);
        
        public Tag (string pattern, string description, ColorScheme colors) {
            this.pattern = pattern;
            this.description = description;
            this.colors = colors;

            hits = 0;
            _enabled = true;
        }

        public bool applies_to (string text) {
            if (!this.enabled) return false;

            if (this.is_regex) {
                RegexCompileFlags reflags = 0;

                if (!this.is_case_sensitive) {
                    reflags = RegexCompileFlags.CASELESS;
                }

                Regex regex = new Regex (this.pattern, reflags);
                return regex.match (text);
            } else {
                if (this.is_case_sensitive) {
                    return text.contains (this.pattern);
                } else {
                    return text.up ().contains (this.pattern.up ());
                }
            }

            return false;
        }
    }
}
