/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * tag-row.vala
 *
 * Extended Adw.ActionRow for tags view (listbox) 
 *
 * José Miguel Fonte
 */

namespace Tags {
    [GtkTemplate (ui = "/io/github/phastmike/tags/tag/tag-row.ui")]
    public class TagRow : Gtk.ListBoxRow {
        [GtkChild]
        public Gtk.Label title;
        [GtkChild]
        public Gtk.Label subtitle;
        [GtkChild]
        public Gtk.CheckButton enabled;
        [GtkChild]
        public Gtk.Label hitcounter;

        public Tag tag;
        private Gtk.CssProvider style_provider;
        public string style_class {get; private set;}

        public TagRow (Tag tag) {
            this.tag = tag;
            style_class = generate_unique_name ();

            style_provider = new Gtk.CssProvider ();

            var style_ctx = get_style_context ();
            style_ctx.add_provider_for_display (
                Gdk.Display.get_default (),
                this.style_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_USER
            );

            style_update_css ();

            set_tooltip_text (tag.description);
            enabled.active = tag.enabled;
            enabled.add_css_class (style_class);
            title.label = tag.description;
            title.add_css_class(style_class);
            subtitle.label = tag.pattern;
            hitcounter.label = "%u".printf (tag.hits);
            if (tag.description.length == 0) {
                title.visible = false;
            }

            this.tag.bind_property ("enabled", enabled,  "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            this.tag.bind_property ("description", title, "label", BindingFlags.SYNC_CREATE);
            this.tag.bind_property ("pattern", subtitle, "label", BindingFlags.SYNC_CREATE);

            this.tag.colors.changed.connect ( (cs) => {
                style_update_css ();
            });
        }

        ~TagRow () {
            remove_css_class (style_class);
        }

        void style_update_css () {
            string? lstyle = """
                .%s {
                    font-size: 0.8333em;
                }

                .%s check {
                    color: %s;
                    background-color: %s;
                    /*font-size: 0.8333em;*/
                }
            """.printf (style_class, style_class, tag.colors.fg.to_string (), tag.colors.bg.to_string ());

            style_provider.load_from_data (lstyle.data);
        }

        private string generate_unique_name () {
            string random_input = "%u-%u-%u".
                printf(GLib.Random.next_int (), GLib.Random.next_int (), GLib.Random.next_int());
            var checksum = new Checksum(ChecksumType.SHA256);
            checksum.update(random_input.data, random_input.length);
            return "row-" + checksum.get_string();
        }
    }
}
