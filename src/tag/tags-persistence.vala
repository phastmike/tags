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

    public class TagsPersistence : Object {
        public static async File? open_tags_file_dialog (Gtk.Window? parent_window = null, Cancellable? cancellable = null) {
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
                return file;
            } catch (Error e) {
                message ("Error message: %s".printf (e.message));
            }
            return null;
        }

        public static async File? save_tags_file_dialog (Gtk.Window? parent_window = null, string? suggested_filename, Cancellable? cancellable = null) {
            File? file = null;

            var file_dialog = new Gtk.FileDialog ();
            file_dialog.set_modal (true);
            file_dialog.set_title ("Save Tags");
            file_dialog.set_accept_label ("Save");

            if (suggested_filename != null) {
                file_dialog.set_initial_name (suggested_filename);
            }

            try {
                file = yield file_dialog.save (parent_window, cancellable);
                return file;
            } catch (Error e) {
                message ("Error message: %s".printf (e.message));
            }
            
            return null;
        }
    }
}

