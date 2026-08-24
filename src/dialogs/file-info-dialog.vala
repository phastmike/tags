/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * preferences-window.vala
 *
 * Preferences Window
 *
 * José Miguel Fonte
 */

namespace Tags {
    [GtkTemplate (ui = "/io/github/phastmike/tags/ui/file-info-dialog.ui")]
    public class FileInfoDialog: Adw.Dialog {
        [GtkChild]
        private unowned Adw.ActionRow row_filename;
        [GtkChild]
        private unowned Adw.ActionRow row_folder;
        [GtkChild]
        private unowned Adw.ActionRow row_size;
        [GtkChild]
        private unowned Adw.ActionRow row_lines_n;

        public FileInfoDialog (GLib.File file, Lines lines) {
            row_filename.set_subtitle (file.get_basename ());
            row_folder.set_subtitle (file.get_parent ().get_path ());
            var info = file.query_info ("standard::size", GLib.FileQueryInfoFlags.NONE, null);
            row_size.set_subtitle ("%s bytes".printf(info.get_size ().to_string ()));
            row_lines_n.set_subtitle ("%s".printf(lines.model.get_n_items ().to_string ()));
        }

    }
}
