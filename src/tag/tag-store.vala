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
        private TagStyleStore styles;

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

        public TagStore (TagStyleStore? styles = null) {
            store = new ListStore (typeof(Tag));
            if (styles != null)
                this.styles = styles;
            else
                this.styles = new TagStyleStore ();
        }

        public void hitcounter_reset_all () {
            for (uint j = 0; j < ntags; j++) {
                var tag = model.get_item (j) as Tag;
                tag.hits = 0;
            }
        }

        public void toggle_tag (int nr) requires (nr >= 0 && nr <= 9) {
            if (nr >= ntags) return;
            var tag = model.get_item (nr) as Tag;
            tag.enabled = !tag.enabled;
        }

        public void add_tag (Tag tag, bool prepend = false) {
            if (prepend == true) { 
                store.insert (0, tag);
            } else {
                store.append(tag);
            }
            styles.add_style_for_tag (tag);
        }

        public void remove_tag (Tag to_remove) {
            for (var i = 0; i < store.get_n_items (); i++) {
                var tag = store.get_object (i) as Tag;
                if (tag == to_remove) {
                    store.remove (i);
                    styles.remove_style_for_tag (to_remove);
                    return;
                }
            }
        }

        public void remove_all () {
            store.remove_all ();
        }

        /* Enable/Disable all tags */
        public void set_enable_all (bool enable) {
            Tag tag;
            for (var i = 0; i < model.get_n_items (); i++) {
                tag = model.get_object (i) as Tag;
                tag.enabled = enable;
            }
        }

        public void to_file (File file) {
            Json.Node root = new Json.Node (Json.NodeType.ARRAY);
            Json.Array array = new Json.Array ();

            for (uint i = 0; i < store.get_n_items (); i++) {
                var tag = model.get_object (i) as Tag;
                Json.Node node = Json.gobject_serialize (tag);
                array.add_element (node); 
            }

            root.take_array (array);
            Json.Generator generator = new Json.Generator ();
            generator.pretty = true;
            generator.set_root (root);
            try {
                generator.to_file (file.get_path ());
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
                        //store.append (tag);
                        
                        // FIXME: We need to generate a new UUID for the tag. Lacks persistence support
                        tag.colors.name = Tags.Helpers.generate_uuid ();
                        add_tag (tag);
                    });
                } else {
                    warning ("Oops!.. Something went wrong while decoding json data ...");
                }
            } catch (Error e) {
                warning ("from_file:error: %s", e.message);
            }
        }
    }
}


