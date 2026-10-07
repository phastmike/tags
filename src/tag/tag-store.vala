/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * tag-store.vala
 *
 * Class containing tags - the TagStore 
 *
 * José Miguel Fonte
 */

namespace Tags {
    public class TagStore : Object {
        private ListStore store;

        public GLib.ListModel model {
            get {
                return store as GLib.ListModel;
            }
        }

        public uint ntags {
            get {
                return model.get_n_items ();
            }
        }

        public bool have_changed { get; set; default = false; }

        public TagStore () {
            store = new ListStore (typeof(TagContext));
        }

        public void hitcounter_reset_all () {
            for (uint j = 0; j < ntags; j++) {
                var ctx = model.get_item (j) as TagContext;
                ctx.hits = 0;
            }
        }

        // Auxiliary method to toggle tags by number (0-9) for keyboard shortcuts
        public void toggle_tag (int nr) requires (nr >= 0 && nr <= 9) {
            if (nr >= ntags) return;
            var ctx = model.get_item (nr) as TagContext;
            var tag = ctx.tag;
            tag.enabled = !tag.enabled;
        }

        public void add_tag (Tag tag, bool prepend = false) {
            var ctx = new TagContext (tag);

            if (prepend == true) { 
                store.insert (0, ctx);
            } else {
                store.append(ctx);
            }

            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                ctx.css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            have_changed = true;
            tag.changed.connect (() => {
                have_changed = true;
            });
        }

        public void remove_tag (Tag to_remove) {
            for (var i = 0; i < store.get_n_items (); i++) {
                var ctx = store.get_object (i) as TagContext;
                var tag = ctx.tag;
                if (tag == to_remove) {
                    Gtk.StyleContext.remove_provider_for_display (
                        Gdk.Display.get_default (), ctx.css_provider
                    );
                    store.remove (i);
                    have_changed = true;
                    return;
                }
            }
        }

        public TagContext? get_context_for_tag (Tag tag) {
            for (var i = 0; i < store.get_n_items (); i++) {
                var ctx = store.get_object (i) as TagContext;
                if (ctx.tag == tag) return ctx;
            }
            return null;
        }

        public void remove_all () {
            store.remove_all ();
            have_changed = false;
        }

        /* Enable/Disable all tags */
        public void set_enable_all (bool enable) {
            TagContext ctx;
            for (var i = 0; i < model.get_n_items (); i++) {
                ctx = model.get_object (i) as TagContext;
                ctx.tag.enabled = enable;
            }
        }

        public bool check_if_pattern_exists (string pattern) {
            for (var i = 0; i < model.get_n_items (); i++) {
                var ctx = model.get_object (i) as TagContext;
                if (pattern == ctx.tag.pattern) return true;
            }
            return false;
        }

        public void to_file (File file) {
            Json.Node root = new Json.Node (Json.NodeType.ARRAY);
            Json.Array array = new Json.Array ();

            for (uint i = 0; i < store.get_n_items (); i++) {
                var ctx = model.get_object (i) as TagContext;
                var tag = ctx.tag;
                Json.Node node = Json.gobject_serialize (tag);
                array.add_element (node); 
            }

            root.take_array (array);
            Json.Generator generator = new Json.Generator ();
            generator.pretty = true;
            generator.set_root (root);
            try {
                generator.to_file (file.get_path ());
                have_changed = false;
            } catch (Error e) {
                error ("to_file:error: %s", e.message);
            }
        }

        public async void from_file (File file, Cancellable? cancellable = null, bool preserve_load = false) {
            FileInputStream stream;

            try {
                stream = yield file.read_async (Priority.DEFAULT, cancellable);
                Json.Parser parser = new Json.Parser ();
                yield parser.load_from_stream_async (stream, cancellable);

                if (preserve_load == false) store.remove_all ();

                Json.Node node = parser.get_root ();
                Json.Array array = new Json.Array ();
                if (node.get_node_type () == Json.NodeType.ARRAY) {
                    array = node.get_array ();
                    array.foreach_element ((array, index_, element_node) => {
                        var tag = Json.gobject_deserialize (typeof (Tag), element_node) as Tag;
                        message ("from_file:tag: %s", tag.pattern);
                        tag.dump_to_console ();
                        add_tag (tag);
                    });
                    if (preserve_load == false) have_changed = false;
                } else {
                    warning ("Oops!.. Something went wrong while decoding json data ...");
                }
            } catch (Error e) {
                warning ("from_file:error: %s", e.message);
            }
        }
    }
}

