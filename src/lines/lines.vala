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
        public GLib.ListModel model;

        public signal void loaded_from_file ();
        public signal void load_failed (string err_msg); 

        public static  string[] model_to_array (GLib.ListModel model) {
            var result = new string[model.get_n_items()];
            for (int i = 0; i < model.get_n_items(); i++) {
                var line = model.get_item(i) as Line;
                result[i] = line?.text ?? "";
            }
            return result;
        }

        public Lines () {
            model = new GLib.ListStore (typeof(Line));
        }

        public async void from_file (File file, Cancellable cancellable) {
            try {
                string? line;
                uint count = 0;
                FileInputStream @is = yield file.read_async (Priority.DEFAULT, cancellable);
                DataInputStream dis = new DataInputStream (@is);

                var store = model as GLib.ListStore;
                store.remove_all ();

                try {
                    while ((line = yield dis.read_line_async ()) != null) {
                        for (int i = 0; i < line.length; i++) {
                            if (line.data[i] == '\r') line.data[i] = 0x20;
                        }

                        //FIXME: Bug in string.replace method when replacing \r (0x0d)
                        // WORKAROUND: Iterate and replace... (as above)
                        // line = line.replace ("\r", " ");
                        store.append (new Line (++count, line));
                    }
                    loaded_from_file ();
                } catch (IOError e) {
                    warning (e.message);
                    load_failed (e.message);
                }
            } catch (Error e) {
                warning (e.message);
                load_failed (e.message);
            }
        }

        public async void to_file (File file) {
            Line line;
            StringBuilder str;
            FileOutputStream fsout;

            str = new StringBuilder ();
            str.erase ();
            str.append("");     // Fixes minor bug? Buffer isn't empty !?!?

            // Buffers data to be written
            for (uint i = 0; i < model.get_n_items (); i++) {
                line = model.get_item (i) as Line;
                str.append_printf ("%s\n", line.text);
            }

            try {
                if (file.query_exists () == true) file.@delete ();
                fsout = file.replace (null, false, FileCreateFlags.REPLACE_DESTINATION, null); 
                fsout.write_all_async.begin (str.data, Priority.DEFAULT, null, (obj, res) => {
                    size_t bytes_wr;
                    try {
                        fsout.write_all_async.end (res, out bytes_wr);
                        try {
                            fsout.close_async.begin (Priority.DEFAULT, null, (obj, res) => {
                                try {
                                    fsout.close_async.end (res);
                                } catch (IOError e) {
                                    warning (e.message);
                                }
                            });
                        } catch (IOError e) {
                            warning (e.message);
                        }
                    } catch (Error e) {
                        warning (e.message);
                    }
                });
            } catch (Error e) {
                warning (e.message);
            }
        }
    }
}
