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
        ListStore store;
        public uint ntags {
            get {
                return get_model ().get_n_items ();
            }
        }

        public TagStore () {
            store = new ListStore (typeof(Tag));
        }

        public ListModel get_model () {
            return (ListModel) store;
        }

        public void add_tag (Tag tag, bool prepend = false) {
            if (prepend == true) { 
                store.insert (0, tag);
            } else {
                store.append(tag);
            }
        }

        public void remove_tag (Tag to_remove) {
            Tag tag;
            for (var i = 0; i < store.get_n_items (); i++) {
                tag = get_model ().get_object (i) as Tag;
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
        public void tags_set_enable (bool enable) {
            Tag tag;
            for (var i = 0; i < store.get_n_items (); i++) {
                tag = get_model ().get_object (i) as Tag;
                tag.enabled = enable;
            }
        }

        public void to_file (File file) {
            Json.Node root = new Json.Node (Json.NodeType.ARRAY);
            Json.Array array = new Json.Array ();

            Tag tag;
            for (var i = 0; i < store.get_n_items (); i++) {
                tag = get_model ().get_object (i) as Tag;
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

        public void clear_hit_counters () {
            Tag tag;
            for (var i = 0; i < store.get_n_items (); i++) {
                tag = get_model ().get_object (i) as Tag;
                tag.hits = 0;
            }
        }

    }
}


