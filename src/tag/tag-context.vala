/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * tag-context.vala
 *
 * Tag context (view model) for tag 
 * Also contains a counter class for the hit counter.
 *
 * José Miguel Fonte
 */

namespace Tags {

    public class Counter : Object {
        public uint count { get; private set; default = 0; }

        public Counter () {
            reset ();
        }

        public void increment () {
            if (count < uint.MAX) {
                count++;
            }
        }

        public void decrement () {
            if (count > 0) {
                count--;
            }
        }

        public void reset () {
            count = 0;
        }

        public bool is_zero () {
            return count == 0;
        }
    }

    public class TagContext : Object {
        public Tag              tag             { get; private set; }
        public Counter          hit_counter     { get; private set; default = new Counter (); }
        public Gtk.CssProvider  css_provider    { get; private set; default = new Gtk.CssProvider (); }

        private const string STYLE_PREFIX_ROW  = "row-";
        public  const string STYLE_PREFIX_LINE = "tag-";

        public static string get_style_name_for_row (Tag tag) requires (tag != null) {
            return "%s%s".printf (STYLE_PREFIX_ROW, tag.uuid);
        }

        public static string get_style_name_for_tag (Tag tag) requires (tag != null) {
            return "%s%s".printf (STYLE_PREFIX_LINE, tag.uuid);
        }


        /* CONSTRUCTOR */

        public TagContext (Tag tag) requires (tag != null) {
            this.tag = tag;
            update_css ();
            this.tag.colors.changed.connect (update_css);
        }

        /* DESTRUCTOR */

        /* NOTE: NEEDED ? */
        ~TagContext () {
            this.tag.colors.changed.disconnect (update_css);
        }

        /* METHODS */

        private void update_css () {
            string css_row =
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

            string css_line =
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

            css_provider.load_from_string (css_row + css_line);
        }
    }
}
