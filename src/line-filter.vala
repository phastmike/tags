/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * FILENAME.vala
 *
 * DESCRIPTION
 * 
 *
 * José Miguel Fonte
 */

namespace Gtat {

    public class LineFilter : Object {
        private bool _enabled;

        public bool enabled { 
            get {
                return _enabled;
            }
            set {
                _enabled = value;
                print("Enabled changed to: %s\n", _enabled.to_string ());
                enable_changed (enabled);
            }
        }

        public string pattern;
        public string description;
        public uint hits;
        public ColorScheme colors;

        public signal void enable_changed (bool enabled);
        
        public LineFilter (string pattern, string description, ColorScheme colors) {
            this.pattern = pattern;
            this.description = description;
            this.colors = colors;

            hits = 0;
            _enabled = true;
        }
    }
}
