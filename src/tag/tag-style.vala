/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * tag-style-store.vala
 *
 * Class containing style providers for tags
 *
 * José Miguel Fonte
 */

namespace Tags {

    public class TagStyle : Object {
        public unowned Tag tag;
        public Gtk.CssProvider provider;

        public const string ROW_PREFIX = "row-";
        public const string LINE_PREFIX = "tag-";

        public static string get_style_name_for_row (Tag tag) requires (tag != null) {
            return "%s%s".printf (ROW_PREFIX, tag.get_uuid ());
        }

        public static string get_style_name_for_tag (Tag tag) requires (tag != null) {
            return "%s%s".printf (LINE_PREFIX, tag.get_uuid ());
        }

        public TagStyle (Tag tag) {
            this.tag = tag;
            this.tag.colors.changed.connect (update_css);
            provider = new Gtk.CssProvider ();
            update_css ();
        }

        ~TagStyle () {
            this.tag.colors.changed.disconnect (update_css);
        }

        private void update_css () {
            // Used for Tags View
            string css_tag_row =
"""
.%s label {
font-size: 0.8333em;
}
.%s check {
color: %s;
background-color: %s;
}
""".printf (get_style_name_for_row (tag),
        get_style_name_for_row (tag),
        tag.colors.fg.to_string (),
        tag.colors.bg.to_string ()
    );



            // Used for Line View
            string css = 
"""
.%s {
   background-color: %s;
   color: %s;
}
.%s:hover {
    opacity: 0.65;
}
.%s:selected {
  background-color: @theme_selected_bg_color;
  color: @theme_selected_fg_color;
}
""".printf (get_style_name_for_tag (tag),
            tag.colors.bg.to_string (),
            tag.colors.fg.to_string (),
            get_style_name_for_tag (tag),
            get_style_name_for_tag (tag)
           );
            
            provider.load_from_string (css_tag_row + css);
        }
    }
}
