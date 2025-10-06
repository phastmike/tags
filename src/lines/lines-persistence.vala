/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * lines-persistence.vala
 *
 * Class to manage line persistence
 * Loads files and Saves tagged lines
 *
 * José Miguel Fonte
 */

namespace Tags {

    public sealed class LinesPersistence : Object {
        private GLib.ListStore lines;

        /* SIGNALS */

        public signal void load_failed (string err_msg);
        public signal void loaded_from_file (GLib.ListStore lines);

        /* CLASS METHODS */

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
            file_dialog.set_title ("Open File");
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

        public static async File? save_lines_file_dialog (Gtk.Window? parent_window, string? suggested_filename = null, Cancellable? cancellable = null) throws Error {
            var file_dialog = new Gtk.FileDialog ();
            file_dialog.set_modal (true);
            file_dialog.set_title ("Save tagged");
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

        /* INSTANCE METHODS */

        public LinesPersistence () {
            lines = new GLib.ListStore (typeof(Gtk.StringObject));
        }
    }
}
