/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * tag-persistence.vala
 *
 * Class to manage tag persistence
 * Loads and Saves tag json data 
 *
 * José Miguel Fonte
 */

namespace Tags {

    public sealed class TagsPersistence : Object {
        private GLib.ListStore tags;
        //private bool preserve_on_load = false;
    
        /* SIGNALS */
        public signal void saved_to_file (File file);
        public signal void loaded_from_file (GLib.ListStore tags);

        public TagsPersistence () {
            tags = new GLib.ListStore (typeof(Tag));
        }

        // FIXME: If loading at the end, then we should rename the method
        // It should provide only a way to get a file from the user */
        public async void open_tags_file_dialog (Gtk.Window? parent_window = null, Cancellable? cancellable = null) {
            File? file = null;

            var file_dialog = new Gtk.FileDialog ();
            file_dialog.set_title ("Load Tags");
            file_dialog.set_accept_label ("Load");
            file_dialog.set_modal (true);

            var filter1 = new Gtk.FileFilter ();
            filter1.set_filter_name ("Tag files");
            filter1.add_pattern ("*.tags");

            var filter2 = new Gtk.FileFilter ();
            filter2.set_filter_name ("Text files");
            filter2.add_mime_type("text/plain");
            
            var filter3 = new Gtk.FileFilter ();
            filter3.set_filter_name ("All files");
            filter3.add_pattern ("*");

            var file_filters = new ListStore (typeof (Gtk.FileFilter));
            file_filters.append (filter1);
            file_filters.append (filter2);
            file_filters.append (filter3);
            file_dialog.set_filters (file_filters);

            try {
                file = yield file_dialog.open (parent_window, cancellable); 
                from_file (file);
            } catch (Error e) {
                message ("Error message: %s".printf (e.message));
            }
        }

        public async void save_tags_file_dialog (Gtk.TreeModel model, Gtk.Window? parent_window = null, Cancellable? cancellable = null) {
            File? file = null;

            var file_dialog = new Gtk.FileDialog ();
            file_dialog.set_modal (true);
            file_dialog.set_title ("Save Tags");
            file_dialog.set_accept_label ("Save");

            try {
                file = yield file_dialog.save (parent_window, cancellable);
                to_file (file, model);
            } catch (Error e) {
                message ("Error message: %s".printf (e.message));
            }
        }

        /* Could store in a list/collection and provide as return instead of signal */
        public async void from_file (File file, Cancellable? cancellable = null) {
            FileInputStream stream;
            try {
                stream = yield file.read_async (Priority.DEFAULT, cancellable);
                Json.Parser parser = new Json.Parser ();
                yield parser.load_from_stream_async (stream, cancellable);
                /* PRESERVE LOAD? Sense to add on top of other,
                   delegate to consumer, we are just a provider
                   for now */
                tags.remove_all ();
                /**********************************************/
                Json.Node node = parser.get_root ();
                Json.Array array = new Json.Array ();
                if (node.get_node_type () == Json.NodeType.ARRAY) {
                    array = node.get_array ();
                    array.foreach_element ((array, index_, element_node) => {
                        Tag tag = Json.gobject_deserialize (typeof (Tag), element_node) as Tag;
                        tags.append (tag);
                    });
                    loaded_from_file (tags);
                } else {
                    warning ("Oops!.. Something went wrong while decoding json data ...");
                }
            } catch (Error e) {
                warning ("Error message: %s", e.message);
            }
        }

        public void to_file (File file, Gtk.TreeModel tag_store) {
            Json.Node root = new Json.Node (Json.NodeType.ARRAY);
            Json.Array array = new Json.Array ();

            tag_store.foreach ((model, path, iter) => {
                Tag? tag = null;
                model.@get (iter, 0, out tag);
                if (tag == null) return false;
                Json.Node node = Json.gobject_serialize (tag);
                array.add_element (node); 
                return false;
            });

            root.take_array (array);
            Json.Generator generator = new Json.Generator ();
            generator.pretty = true;
            generator.set_root (root);
            try {
                generator.to_file (file.get_path ());
                saved_to_file (file);
            } catch (Error e) {
                warning ("Message: %s", e.message);
            }
        }
    }
}

