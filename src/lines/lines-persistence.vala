/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * lines-persistence.vala
 *
 * Class to manage tag persistence
 * Loads and Saves tag json data 
 *
 * José Miguel Fonte
 */

namespace Tags {

    public sealed class LinesPersistence : Object {
        private GLib.ListStore lines;

        /* SIGNALS */
        public signal void load_failed (string err_msg);
        public signal void loaded_from_file (GLib.ListStore lines);

        public LinesPersistence () {
            lines = new GLib.ListStore (typeof(Gtk.StringObject));
        }

        ~LinesPersistence () {
            message ("Destroyed LinesPersistence instance...");
        }

        public static async File? open_lines_file_dialog (Gtk.Window? parent_window = null, Cancellable? cancellable = null) throws Error {
            var file_filter1 = new Gtk.FileFilter ();
            file_filter1.add_mime_type ("text/plain");
            file_filter1.set_filter_name ("Text files");

            var file_filter2 = new Gtk.FileFilter ();
            file_filter2.add_pattern ("*");
            file_filter2.set_filter_name ("All files");

            var file_filters = new ListStore (typeof (Gtk.FileFilter));
            file_filters.append (file_filter1);
            file_filters.append (file_filter2);

            var file_dialog = new Gtk.FileDialog ();
            file_dialog.set_modal (true);
            file_dialog.set_title ("Open log file");
            file_dialog.set_accept_label ("Open");
            file_dialog.set_filters (file_filters);

            try {
                var file = yield file_dialog.open (parent_window, cancellable);
                return file;
            } catch (Error e) {
                warning (e.message);
                throw e;
                return null;
            }
        }

        public async File? save_lines_file_dialog (Gtk.Window? parent_window, string? suggested_filename = null, Cancellable? cancellable = null) throws Error {
            var file_dialog = new Gtk.FileDialog ();
            file_dialog.set_modal (true);
            file_dialog.set_title ("Save tagged lines to file");
            file_dialog.set_accept_label ("Save");

            if (suggested_filename != null) {
                file_dialog.set_initial_name (suggested_filename);
            }

            try {
                var file = yield file_dialog.save (parent_window, null);
                return file;
            } catch (Error e) {
                message (e.message);
                throw e;
                return null;
            }
        }

        public async void from_file (File file, Cancellable cancellable) {
            try {
                FileInputStream @is = yield file.read_async (Priority.DEFAULT, cancellable);
                DataInputStream dis = new DataInputStream (@is);
                string? line;

                try {
                    while ((line = yield dis.read_line_async ()) != null) {
                        line = line.replace ("\r", "");
                        lines.append (new Gtk.StringObject (line));
                    }
                    loaded_from_file (lines);
                } catch (IOError e) {
                    warning (e.message);
                    load_failed (e.message);
                }
            } catch (Error e) {
                warning (e.message);
                load_failed (e.message);
            }
        }

        public async void to_file (File file, Gtk.TreeModel line_store) {
            StringBuilder str;
            FileOutputStream fsout;

            str = new StringBuilder ();
            str.append("");     // Fixes minor bug? Buffer isn't empty !?!?

            line_store.foreach ((model, path, iter) => {
                string line;
                model.@get (iter, LinesTreeView.Columns.LINE_TEXT, out line);
                str.append_printf ("%s\n", line);
                return false;
            });

            try {
                fsout = file.replace (null, false, FileCreateFlags.REPLACE_DESTINATION, null); 
                fsout.write_all_async.begin (str.data, Priority.DEFAULT, null, (obj, res) => {
                    fsout.close ();
                });
            } catch (Error e) {
                warning (e.message);
            }
        }

    }
}
