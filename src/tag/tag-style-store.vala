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
    public class TagStyleStore : Object {
        private ListStore store;

        public GLib.ListModel model {
            get {
                return store as GLib.ListModel;
            }
        }

        public uint nstyles {
            get {
                return model.get_n_items ();
            }
        }

        public TagStyleStore () {
            store = new ListStore (typeof(TagStyle));
        }

        public void add_style_for_tag (Tag tag) {
            TagStyle style = new TagStyle (tag);
            store.append(style);
            Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (),
                                                      style.provider,
                                                      Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        public void remove_style_for_tag (Tag tag) {
            for (uint i = 0; i < nstyles; i++) {
                var style = model.get_item (i) as TagStyle;
                if (style.tag == tag) {
                    store.remove (i);
                    Gtk.StyleContext.remove_provider_for_display (Gdk.Display.get_default (), style.provider);
                    break;
                }
            }
        }

    }

}
