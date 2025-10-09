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
    public class TagRow : Adw.ActionRow {
        [GtkChild]
        public Gtk.CheckButton enabled;
        [GtkChild]
        public Gtk.Label hitcounter;

        Tag tag;
        string uuid;

        public TagRow (Tag tag) {
            uuid = generate_random_hash ();
            enabled.active = tag.enabled;
            title = tag.description;
            subtitle = tag.pattern;
            hitcounter.label = "%u".printf (tag.hits);

            string? lstyle = """
                .%s {
                    color: %s;
                    background-color: %s;
                    /*font-size: 0.8333em;*/
                }
            """.printf (uuid, tag.colors.fg.to_string (), tag.colors.bg.to_string ());

            message ("Style:\n%s", lstyle);

            var provider = new Gtk.CssProvider ();
            provider.load_from_data (lstyle.data);
            add_css_class (uuid);
            Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        }

        ~TagRow () {
            remove_css_class (uuid);
        }

        string generate_random_hash() {
            // Create a random string using GLib.Random
            string random_input = "%u-%u-%u".printf(GLib.Random.next_int (), GLib.Random.next_int (), GLib.Random.next_int());
            // Hash it
            var checksum = new Checksum(ChecksumType.SHA256);
            checksum.update(random_input.data, random_input.length);
            return "row-" + checksum.get_string();
        }
    }
}
