/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * tag-store.vala
 *
 * Class containing the tags - the TagStore 
 *
 * José Miguel Fonte
 */

namespace Tags {

    public class TagStore : Object {
        public GLib.ListModel model;
        public ListStore store;

        public uint ntags {
            get {
                return model.get_n_items ();
            }
        }

        public TagStore () {
            model = new ListStore (typeof(Tag));
            //add_tag (new Tag ("Teste1", "1Teste", new ColorScheme ("teste", null, null)));
            //add_tag (new Tag ("Teste2", "2Teste", new ColorScheme ("teste", null, null)));
        }

        /* redundant ? */
        public ListModel get_model () {
            return (ListModel) model;
        }

        public void add_tag (Tag tag, bool prepend = false) {
            var store = model as GLib.ListStore;

            if (prepend == true) { 
                store.insert (0, tag);
            } else {
                store.append(tag);
            }
        }

        public void remove_tag (Tag to_remove) {
            Tag tag;
            for (var i = 0; i < store.get_n_items (); i++) {
                tag = store.get_object (i) as Tag;
                if (tag == to_remove) {
                    store.remove (i);
                    return;
                }
            }
        }

        public void clear_tags () {
            store.remove_all ();
        }

        /* Is this really needed? Remind me again about the purpose */
        /* Enable all ? */
        public void tags_set_enable (bool enable) {
            Tag tag;
            for (var i = 0; i < store.get_n_items (); i++) {
                //tag = get_model ().get_object (i) as Tag;
                tag = store.get_object (i) as Tag;
                tag.enabled = enable;
            }
        }

        public void to_file (File file) {
            Json.Node root = new Json.Node (Json.NodeType.ARRAY);
            Json.Array array = new Json.Array ();

            Tag tag;
            for (var i = 0; i < store.get_n_items (); i++) {
                tag = store.get_object (i) as Tag;
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
                error ("Json.Generator::to_file error: %s", e.message);
            }
        }

        public async void from_file (File file, Cancellable? cancellable = null) {
            FileInputStream stream;
            var store = model as GLib.ListStore;

            try {
                stream = yield file.read_async (Priority.DEFAULT, cancellable);
                Json.Parser parser = new Json.Parser ();
                yield parser.load_from_stream_async (stream, cancellable);
                /* PRESERVE LOAD? Sense to add on top of other,
                   delegate to consumer, we are just a provider
                   for now */
                store.remove_all ();
                /**********************************************/
                Json.Node node = parser.get_root ();
                Json.Array array = new Json.Array ();
                if (node.get_node_type () == Json.NodeType.ARRAY) {
                    array = node.get_array ();
                    array.foreach_element ((array, index_, element_node) => {
                        Tag tag = Json.gobject_deserialize (typeof (Tag), element_node) as Tag;
                        store.append (tag);
                    });
                    //loaded_from_file (tags);
                } else {
                    warning ("Oops!.. Something went wrong while decoding json data ...");
                }
            } catch (Error e) {
                warning ("Error message: %s", e.message);
            }
        }

        public void clear_hit_counters () {
            Tag tag;
            for (var i = 0; i < store.get_n_items (); i++) {
                tag = store.get_object (i) as Tag;
                tag.hits = 0;
            }
        }
    }
}


