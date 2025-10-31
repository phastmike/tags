/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * ui-dialogs.vala
 *
 * Class to provide static methods for: 
 * - Open/Save file dialogs for document files - Lines
 * - Open/Save file dialogs for tag files - Tags 
 *
 * José Miguel Fonte
 */

namespace Tags.UIDialogs {

    public static async File? file_open_lines (Gtk.Window? parent_window = null, Cancellable? cancellable = null) throws Error {
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
        }
    }

    public static async File? file_save_lines (Gtk.Window? parent_window, Cancellable? cancellable = null, string? suggested_filename = null) throws Error {
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
        }
    }

    public static async File? file_open_tags (Gtk.Window? parent_window = null, Cancellable? cancellable = null) {
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

    public static async File? file_save_tags (Gtk.Window? parent_window = null, Cancellable? cancellable = null, string? suggested_filename = null) {
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
