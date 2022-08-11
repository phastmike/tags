/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * color-scheme.vala
 *
 * Represents a color scheme composed by:
 * - name
 * - freground color
 * - background color
 *
 * José Miguel Fonte
 */

namespace Tagger {
    public class ColorScheme : Object {
        private string _name;
        private Gdk.RGBA? _fg;
        private Gdk.RGBA? _bg;

        public string name {
            get { return _name; }
            set { _name = value; changed (); }
        }
            
        public Gdk.RGBA? fg {
            get { return _fg; }
            set { _fg = value; changed (); }
        }

        public Gdk.RGBA? bg {
            get { return _bg; }
            set { _bg = value; changed (); }
        }
        
        public signal void changed ();

        public ColorScheme (string name, Gdk.RGBA? fg, Gdk.RGBA? bg) {
            _name = name;
            _fg = fg;
            _bg = bg;
        }
    }
}
