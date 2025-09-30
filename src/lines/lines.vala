/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * lines-model.vala
 *
 * Contains multiple lines.
 * Class wrapper for GLib.ListStore/ListModel.
 */

namespace Tags {
    public class Lines : Object {

        public static  string[] model_to_array (GLib.ListModel model) {
            var result = new string[model.get_n_items()];
            for (int i = 0; i < model.get_n_items(); i++) {
                var line = model.get_item(i) as Line;
                result[i] = line?.text ?? "";
            }
            return result;
        }

        public GLib.ListModel model;

        public Lines () {
            model = new GLib.ListStore (typeof(Line));
        }

        public async void from_file (File file, Cancellable cancellable) {
            try {
                string? line;
                FileInputStream @is = yield file.read_async (Priority.DEFAULT, cancellable);
                DataInputStream dis = new DataInputStream (@is);

                try {
                    while ((line = yield dis.read_line_async ()) != null) {
                        for (int i = 0; i < line.length; i++) {
                            if (line.data[i] == '\r') line.data[i] = 0x20;
                        }

                        //FIXME: Bug in string.replace method when replacing \r (0x0d)
                        // WORKAROUND: Iterate and replace... (as above)
                        //line = line.replace ("\r", " ");

                        var store = (GLib.ListStore) model;
                        store.remove_all ();
                        store.append (new Gtk.StringObject (line));
                    }
                    //loaded_from_file (lines);
                } catch (IOError e) {
                    warning (e.message);
                    //load_failed (e.message);
                }
            } catch (Error e) {
                warning (e.message);
                //load_failed (e.message);
            }
        }
    }
}
