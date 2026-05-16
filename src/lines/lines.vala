/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * lines.vala
 *
 * Contains multiple lines.
 * Class wrapper for GLib.ListStore/ListModel.
 */

namespace Tags {
    public class Lines : Object {
        public GLib.ListModel model;

        public static  string[] model_to_array (GLib.ListModel model) {
            var result = new string[model.get_n_items()];
            for (int i = 0; i < model.get_n_items(); i++) {
                var line = model.get_item(i) as Line;
                result[i] = line?.text ?? "";
            }
            return result;
        }

        public signal void loaded_from_file ();

        public Lines () {
            model = new GLib.ListStore (typeof(Line));
        }

        public async string? from_file (File file, Cancellable cancellable) {
            string? err_msg = null;

            try {
                string? line;
                uint count = 0;
                FileInputStream @is = yield file.read_async (Priority.DEFAULT, cancellable);
                DataInputStream dis = new DataInputStream (@is);

                // Temporary store to hold lines while loading
                var temp_store = new GLib.ListStore (typeof(Line));
                try {
                    while ((line = yield dis.read_line_async ()) != null) {
                        // NOTE: Bug in string.replace method when replacing \r (0x0d)
                        // WORKAROUND - Iterate and replace... (as below)
                        //line = line.replace ("\r", " "); <-- This does not work as expected
                        for (int i = 0; i < line.length; i++) {
                            if (line.data[i] == '\r') line.data[i] = 0x20;
                        }
                        // Use make_valid to clear unprintable characters and ensure valid UTF-8 encoding
                        temp_store.append (new Line (++count, line.make_valid ()));
                    }

                    uint size = temp_store.get_n_items();
                    Line[] array = new Line[size];
                    for (int i = 0; i < size; i++) {
                        var line_obj = temp_store.get_item(i) as Line;
                        array[i] = line_obj;
                    }
                    var store = model as GLib.ListStore;
                    store.splice (0, model.get_n_items (), array);
                } catch (IOError e) {
                    warning (e.message);
                    err_msg = e.message; 
                    return err_msg;
                }
            } catch (Error e) {
                warning (e.message);
                err_msg = e.message; 
                return err_msg;
            }
            return err_msg;
        }
    }
}
