/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * lines-persistence-manager.vala
 *
 * Class to manage tag persistence
 * Loads and Saves tag json data 
 *
 * José Miguel Fonte
 */

namespace Tags {

    public sealed class LinesPersistence : Object {

        public LinesPersistence () {

        }

        public async File? open_lines_file_dialog (Gtk.Window? parent_window = null, Cancellable? cancellable = null) {
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

            /*
            if (file_opened != null) {
                file_dialog.set_initial_folder (file_opened.get_parent ());
            }
            */

            try {
                var file = yield file_dialog.open (parent_window, cancellable);
                //open_file (new_file);
                return file;
            } catch (Error e) {
                message (e.message);
                /*
                if (e.code != 2) {
                    show_dialog ("Open error", "Could not open file: %s (%d)".printf (e.message, e.code));
                }
                */
                return null;
            }
        }

        /*
        public void from_file (File file) {
            var cancel_open = new Cancellable ();
            var type = file.query_file_type (FileQueryInfoFlags.NONE);

            file_opened = file;

            if (type != FileType.REGULAR) {
                var toast = new Adw.Toast ("'%s' is not a regular file ...".printf(file.get_basename ()));
                toast.set_timeout (3);
                overlay.add_toast (toast);
                return;
            }

            var dialog = new Adw.AlertDialog ("Loading File", file.get_basename ());

            dialog.add_response ("cancel", "_Cancel");
            dialog.set_response_appearance ("cancel",Adw.ResponseAppearance.SUGGESTED);
            dialog.set_default_response ("cancel");
            dialog.set_close_response ("cancel");

            dialog.response.connect ((response) => {
                if (response == "cancel") {
                    cancel_open.cancel ();
                    button_open_file.set_sensitive (true);
                }
            });

            // Sets title for gnome shell window identity
            // Should only do it on success (set_file_ended!!!!)
            set_title (file.get_basename ());
            window_title.set_subtitle (file.get_basename ());
            window_title.set_tooltip_text (file.get_path ());

            handler_id = lines_treeview.set_file_ended.connect ( ()=> {
                save_tagged_enable ();
                // Here we check if application property autoload tags is enabled
                // FIXME: What to do if we already have tags inserted, merged or replace?

                if (Preferences.instance ().tags_autoload == true) {
                    file_tags = File.new_for_path (file.get_path () + ".tags");
                    if (file_tags.query_exists ()) {
                        //set_tags (file_tags);
                        load_tags_from_file (file_tags);
                    }

                    count_tag_hits ();
                }

                button_open_file.set_sensitive (true);
                lines_treeview.set_file_ended.connect ( ()=> {
                    save_tagged_enable ();
                    // Here we check if application property autoload tags is enabled
                    // FIXME: What to do if we already have tags inserted, merged or replace?

                    if (Preferences.instance ().tags_autoload == true) {
                        file_tags = File.new_for_path (file_opened.get_path () + ".tags");
                        if (file_tags.query_exists ()) {
                            //set_tags (file_tags);
                            load_tags_from_file (file_tags);
                        }

                        count_tag_hits ();
                    }

                    button_open_file.set_sensitive (true);
                    dialog.close ();
                    minimap.set_array (lines_treeview.model_to_array ());
                });
                dialog.close ();
                minimap.set_array (lines_treeview.model_to_array ());
            });

            dialog.present (this);
            lines_treeview.set_file (file, cancel_open);
            button_open_file.set_sensitive (false);
        }
        */

    }
}
