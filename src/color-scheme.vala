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
    public class ColorScheme : Object, Json.Serializable {
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

        // Json.Serializable methods

        public override Json.Node serialize_property (string property_name, Value @value, ParamSpec pspec) {
            if (@value.type ().is_a (typeof (Gdk.RGBA))) {
                var obj = (Gdk.RGBA?) @value.get_boxed();
                if (obj != null) {
                    var node = new Json.Node (Json.NodeType.VALUE);
                    node.set_string (((Gdk.RGBA?) obj).to_string ());
                    return node;
                }
            }
            
            return default_serialize_property (property_name, @value, pspec);
        }

        public override bool deserialize_property (string property_name, out Value @value, ParamSpec pspec, Json.Node property_node) {
            if (property_name == "fg" || property_name == "bg") {
                Gdk.RGBA? rgba = Gdk.RGBA ();
                rgba.parse (property_node.get_string ());
                @value = Value (typeof (Gdk.RGBA));
                @value.set_boxed ((Gdk.RGBA *) rgba);
                return true;
            }

            return default_deserialize_property (property_name, out @value, pspec, property_node);
        }
    }
}
