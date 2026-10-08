/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * file-info-dialog.vala
 *
 * File information Dialog Window
 *
 * José Miguel Fonte
 */

namespace Tags {
    [GtkTemplate (ui = "/io/github/phastmike/tags/ui/file-info-dialog.ui")]
    public class FileInfoDialog: Adw.PreferencesDialog {
        [GtkChild]
        private unowned Adw.ActionRow row_filename;
        [GtkChild]
        private unowned Adw.ActionRow row_folder;
        [GtkChild]
        private unowned Adw.ActionRow row_size;
        [GtkChild]
        private unowned Adw.ActionRow row_lines_n;
        [GtkChild]
        private unowned Gtk.Button button_copy;
        [GtkChild]
        private unowned Gtk.Button button_browse;

        enum MULTIPLIER {
            B = 0,
            kB = 1,
            MB = 2,
            GB = 3,
            TB = 4;

            public string to_string () {
                switch (this) {
                    case MULTIPLIER.B:
                        return "Bytes";
                    case MULTIPLIER.kB:
                        return "kB";
                    case MULTIPLIER.MB:
                        return "MB";
                    case MULTIPLIER.GB:
                        return "GB";
                    case MULTIPLIER.TB:
                        return "TB";
                }
                return "";
            }
        }

        public FileInfoDialog (GLib.File file, LineStore lines) {
            row_filename.set_subtitle (file.get_basename ());
            row_filename.set_tooltip_text (file.get_basename ());
            row_folder.set_subtitle (file.get_parent ().get_path ());
            row_folder.set_tooltip_text (file.get_parent ().get_path ());
            try {
                var info = file.query_info ("standard::size", GLib.FileQueryInfoFlags.NONE, null);
                uint n = 0;
                double size = (double) info.get_size ();
                MULTIPLIER mult = MULTIPLIER.B;

                /*
                Go figure,someone thinks that mixing
                base 10 with base 2 number makes sense.
                Should use 1024 as divider but for consistency sake...
                */

                while (size > 1000) {
                    size /= 1000;
                    n++;
                }

                mult = (MULTIPLIER) n;
                size = Math.round (size * 10) / 10.0;
                
                if (mult == MULTIPLIER.B) {
                    row_size.set_subtitle ("%0.0f %s".printf(size, mult.to_string ()));
                } else {
                    row_size.set_subtitle ("%0.1f %s".printf(size, mult.to_string ()));
                }

                row_lines_n.set_subtitle ("%s".printf(lines.model.get_n_items ().to_string ()));

                button_browse.clicked.connect (() => {
                    try {
                        var f = File.new_for_path (file.get_parent ().get_path ());
                        var uri = f.get_uri();
                        AppInfo.launch_default_for_uri (uri, null);
                    } catch (Error e) {
                        warning ("Failed to open folder: %s", e.message);
                    }
                });

                button_copy.clicked.connect (() => {
                    var text = file.get_path ();
                    get_clipboard ().set_text (text);
                    var toast = new Adw.Toast (_("%d bytes copied".printf (text.length)));
                    toast.set_timeout (2);
                    add_toast (toast);
                });
            } catch (Error e) {
                warning ("Failed to get file info: %s", e.message);
                return;
            }
        }
    }
}
