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
    public class FileInfoDialog: Adw.Window {
        [GtkChild]
        private unowned Adw.ActionRow row_filename;
        [GtkChild]
        private unowned Adw.ActionRow row_folder;
        [GtkChild]
        private unowned Adw.ActionRow row_size;
        [GtkChild]
        private unowned Adw.ActionRow row_lines_n;
        [GtkChild]
        private unowned Gtk.Button button_browse;

        enum MULTIPLIERS {
            B = 0,
            kB = 1,
            MB = 2,
            GB = 3,
            TB = 4;

            public string to_string () {
                switch (this) {
                    case MULTIPLIERS.B:
                        return "Bytes";
                    case MULTIPLIERS.kB:
                        return "kB";
                    case MULTIPLIERS.MB:
                        return "MB";
                    case MULTIPLIERS.GB:
                        return "GB";
                    case MULTIPLIERS.TB:
                        return "TB";
                }
                return "";
            }
        }

        public FileInfoDialog (Gtk.Application app, GLib.File file, Lines lines) {
            Object(application: app, transient_for: app.active_window, modal: true);

            row_filename.set_subtitle (file.get_basename ());
            row_folder.set_subtitle (file.get_parent ().get_path ());
            var info = file.query_info ("standard::size", GLib.FileQueryInfoFlags.NONE, null);

            uint n = 0;
            double size = (double) info.get_size ();
            MULTIPLIERS mult= MULTIPLIERS.B;

            /*
            Go figure,someone thinks that applying
            base 10 rules to a base 2 number makes sense.
            Should use 1024 as divider but for consistency sake...
            */

            while (size > 1000) {
                size /= 1000;
                n++;
            }

            mult = n;
            size = Math.round (size * 10) / 10.0;
            
            if (mult == MULTIPLIERS.B) {
                row_size.set_subtitle ("%0.0f %s".printf(size, mult.to_string ()));
            } else {
                row_size.set_subtitle ("%0.1f %s".printf(size, mult.to_string ()));
            }
            //row_size.set_subtitle ("%0.1f %s".printf(size, mult.to_string ()));
            //row_size.set_tooltip_text ("%s bytes".printf(info.get_size ().to_string ()));
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
            
            //present ();
        }
    }
}
