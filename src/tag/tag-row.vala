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
    [GtkTemplate (ui = "/io/github/phastmike/tags/ui/tag-row.ui")]
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
        public string style_class {get; private set;}

        public double drag_x;
        public double drag_y;

        public TagRow (Tag tag) {
            drag_x = 0.0;
            drag_y = 0.0;

            this.tag = tag;
            // FIXME: Need to address these ui styles properly
            style_class = "row-%s".printf (tag.colors.name);

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
            this.tag.bind_property ("hits", hitcounter, "label", BindingFlags.SYNC_CREATE, (binding, source_value, ref target_value) => {
                target_value.set_string (source_value.get_uint ().to_string ());
                return true;
            }, null);

            tag.enable_changed.connect ( (enabled) => {
                if (enabled == true) {
                    remove_css_class ("dimmed");
                } else {
                    add_css_class ("dimmed");
                }
            });
            
            tag.notify["description"].connect ( () => {
                set_tooltip_text (tag.description);
            });
        }

        ~TagRow () {
            remove_css_class (style_class);
        }
    }
}
