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
        public Tag tag;
        public Gtk.CssProvider provider;

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
            string css_tag_row = 
"""

.row-%s label {
font-size: 0.8333em;
}

.row-%s check {
color: %s;
background-color: %s;
/*font-size: 0.8333em;*/
}

""".printf (tag.colors.name,
                tag.colors.name,
                tag.colors.fg.to_string (),
                tag.colors.bg.to_string ()
            );

            string css = 
"""
.tag-%s {
   background-color: %s;
   color: %s;
}

.tag-%s:hover {
    opacity: 0.65;
  /*background-color: @theme_selected_bg_color;*/
  /*color: @theme_selected_fg_color;*/
  /*background-color: alpha(currentColor, 0.07);*/
}

.tag-%s:selected {
  background-color: @theme_selected_bg_color;
  color: @theme_selected_fg_color;
}
"""
            .printf (tag.colors.name,
                tag.colors.bg.to_string (),
                tag.colors.fg.to_string (),
                tag.colors.name,
                tag.colors.name
            );
            
            provider.load_from_string (css_tag_row + css);
            message ("update CSS class: tag-%s\n%s", tag.colors.name, css_tag_row + css);
        }
    }
}
