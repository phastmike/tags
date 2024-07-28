/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * window.vala
 *
 * Main application Window class
 *
 * José Miguel Fonte
 */

namespace Tags {
    [GtkTemplate (ui = "/io/github/phastmike/tags/window.ui")]
    public class Window : Adw.ApplicationWindow {
        [GtkChild]
        unowned Gtk.Button button_open_file;
        [GtkChild]
        unowned Adw.SplitButton button_tags;
        [GtkChild]
        unowned Adw.WindowTitle window_title;
        [GtkChild]
        unowned Adw.ToastOverlay overlay;
        
        private Gtk.Paned paned;
        private LinesTreeView lines_treeview;
        private TagsTreeView tags_treeview;
        private double paned_last_position = 0.778086;
        private File? file_opened = null;
        private File? file_tags = null;
        private bool tags_changed = false;

        private ActionEntry[] WINDOW_ACTIONS = {
            { "add_tag", add_tag },
            { "remove_all_tags", remove_all_tags },
            { "load_tags", load_tags },
            { "save_tags", save_tags },
            { "save_tagged", save_tagged },
            { "hide_untagged_lines", hide_untagged_lines, null, "false", null},
            { "toggle_tags_view", toggle_tags_view, null, "false", null},
            { "copy", copy},
            { "toggle_tag_1", toggle_tag_1},
            { "toggle_tag_2", toggle_tag_2},
            { "toggle_tag_3", toggle_tag_3},
            { "toggle_tag_4", toggle_tag_4},
            { "toggle_tag_5", toggle_tag_5},
            { "toggle_tag_6", toggle_tag_6},
            { "toggle_tag_7", toggle_tag_7},
            { "toggle_tag_8", toggle_tag_8},
            { "toggle_tag_9", toggle_tag_9},
            { "toggle_tag_0", toggle_tag_0},
            { "only_tag_1", only_tag_1},
            { "only_tag_2", only_tag_2},
            { "only_tag_3", only_tag_3},
            { "only_tag_4", only_tag_4},
            { "only_tag_5", only_tag_5},
            { "only_tag_6", only_tag_6},
            { "only_tag_7", only_tag_7},
            { "only_tag_8", only_tag_8},
            { "only_tag_9", only_tag_9},
            { "only_tag_0", only_tag_0},
            { "enable_all_tags", enable_all_tags },
            { "disable_all_tags", disable_all_tags },
            { "prev_hit", prev_hit },
            { "next_hit", next_hit }
        };

        public Window (Gtk.Application app) {
            Object (application: app);

            this.add_action_entries(this.WINDOW_ACTIONS, this);
            app.set_accels_for_action("win.add_tag", {"<primary>n"});
            app.set_accels_for_action("win.save_tagged", {"<primary>s"});
            app.set_accels_for_action("win.hide_untagged_lines", {"<primary>h"});
            app.set_accels_for_action("win.toggle_tags_view", {"<primary>f"});
            app.set_accels_for_action("win.copy", {"<primary>c"});
            app.set_accels_for_action("win.toggle_tag_1", {"<alt>1"});
            app.set_accels_for_action("win.toggle_tag_2", {"<alt>2"});
            app.set_accels_for_action("win.toggle_tag_3", {"<alt>3"});
            app.set_accels_for_action("win.toggle_tag_4", {"<alt>4"});
            app.set_accels_for_action("win.toggle_tag_5", {"<alt>5"});
            app.set_accels_for_action("win.toggle_tag_6", {"<alt>6"});
            app.set_accels_for_action("win.toggle_tag_7", {"<alt>7"});
            app.set_accels_for_action("win.toggle_tag_8", {"<alt>8"});
            app.set_accels_for_action("win.toggle_tag_9", {"<alt>9"});
            app.set_accels_for_action("win.toggle_tag_0", {"<alt>0"});
            app.set_accels_for_action("win.only_tag_1", {"<primary>1"});
            app.set_accels_for_action("win.only_tag_2", {"<primary>2"});
            app.set_accels_for_action("win.only_tag_3", {"<primary>3"});
            app.set_accels_for_action("win.only_tag_4", {"<primary>4"});
            app.set_accels_for_action("win.only_tag_5", {"<primary>5"});
            app.set_accels_for_action("win.only_tag_6", {"<primary>6"});
            app.set_accels_for_action("win.only_tag_7", {"<primary>7"});
            app.set_accels_for_action("win.only_tag_8", {"<primary>8"});
            app.set_accels_for_action("win.only_tag_9", {"<primary>9"});
            app.set_accels_for_action("win.only_tag_0", {"<primary>0"});
            app.set_accels_for_action("win.enable_all_tags", {"<alt>e"});
            app.set_accels_for_action("win.disable_all_tags", {"<alt>d"});
            app.set_accels_for_action("win.prev_hit", {"F2"});
            app.set_accels_for_action("win.next_hit", {"F3"});
            
            save_tagged_disable ();
            
            tags_treeview = new TagsTreeView (app);
            lines_treeview = new LinesTreeView (app, tags_treeview.get_model ());
            
            lines_treeview.row_activated.connect ((path, column) => {
                string line_text;
                Gtk.TreeIter iter;

                var selection = lines_treeview.get_selection ();
                selection.set_mode (Gtk.SelectionMode.SINGLE);
                selection.get_selected (null, out iter);
                lines_treeview.get_model ().@get (iter, LinesTreeView.Columns.LINE_TEXT, out line_text, -1);
                selection.set_mode (Gtk.SelectionMode.MULTIPLE);

                var tag_dialog = new TagDialogWindow (app, line_text);
                tag_dialog.added.connect ((tag, add_to_top) => {
                    tag.enable_changed.connect ((enabled) => {
                        lines_treeview.line_store_filter.refilter ();
                    });
                    tags_treeview.add_tag (tag, add_to_top);
                    count_tag_hits ();
                });

                tag_dialog.show ();
            });

            
            tags_treeview.row_activated.connect ((path, column) => {
                Tag tag;
                Gtk.TreeIter iter;

                tags_treeview.get_selection ().get_selected (null, out iter);
                tags_treeview.get_model ().@get (iter, 0, out tag);

                var tag_dialog = new TagDialogWindow.for_editing (app, tag);

                tag_dialog.edited.connect ((t) => {
                    tags_changed = true;
                    if (lines_treeview.hide_untagged) 
                        lines_treeview.line_store_filter.refilter ();
                    count_tag_hits ();
                });

                tag_dialog.deleted.connect ((tag) => {
                    tags_changed = true;
                    tags_treeview.remove_tag (tag);
                    if (lines_treeview.hide_untagged) { 
                        lines_treeview.line_store_filter.refilter ();
                    }
                });

                tag_dialog.show ();
            });

            paned = new Gtk.Paned (Gtk.Orientation.VERTICAL);
            overlay.set_child (paned);

            paned.notify["position"].connect ((s,p) => {
                var view_height = paned.get_allocated_height ();
                
                if (view_height == 0) return;

                var action = this.lookup_action ("toggle_tags_view");

                /* Change menu action state if manually hidden */
                if (paned.get_position () >= view_height - 5) {
                    action.change_state (new Variant.boolean (true));
                } else {
                    action.change_state (new Variant.boolean (false));
                }
            });

            var scrolled_lines = new Gtk.ScrolledWindow ();
            scrolled_lines.set_kinetic_scrolling (true);
            scrolled_lines.set_placement (Gtk.CornerType.TOP_LEFT);
            scrolled_lines.set_overlay_scrolling (true);
            scrolled_lines.set_child (lines_treeview);
            //scrolled_lines.set_policy (Gtk.PolicyType.ALWAYS, Gtk.PolicyType.ALWAYS);

            var scrolled_tags = new Gtk.ScrolledWindow ();
            scrolled_tags.set_kinetic_scrolling (true);
            scrolled_tags.set_placement (Gtk.CornerType.TOP_LEFT);
            scrolled_tags.set_overlay_scrolling (true);
            scrolled_tags.set_child (tags_treeview);

            paned.set_start_child (scrolled_lines);
            paned.set_end_child (scrolled_tags);
            paned.set_resize_start_child (true);
            paned.set_resize_end_child (true);
            paned.set_wide_handle (true);
            paned.set_position (this.default_height - 47 - 160);

            //paned.queue_draw ();

            button_open_file.clicked.connect ( () => {
                var file_dialog = new Gtk.FileDialog ();
                file_dialog.set_modal (true);
                file_dialog.set_title ("Open log file");
                file_dialog.set_accept_label ("Open");

                var file_filter1 = new Gtk.FileFilter ();
                file_filter1.add_pattern ("*.tags");
                file_filter1.add_mime_type ("text/plain");   // text/*
                file_filter1.set_filter_name ("Text/Log files");

                var file_filter2 = new Gtk.FileFilter ();
                file_filter2.add_pattern ("*");
                file_filter2.set_filter_name ("All files");

                var file_filters = new ListStore (typeof (Gtk.FileFilter));
                file_filters.append (file_filter1);
                file_filters.append (file_filter2);

                file_dialog.set_filters (file_filters);

                if (file_opened != null) {
                    file_dialog.set_initial_folder (file_opened.get_parent ());
                    message ("Set initial file '%s' ...", file_opened.get_parse_name ());
                }

                file_dialog.open.begin (this, null, (obj, res) => {
                    try {
                        this.set_file (file_dialog.open.end (res));
                    } catch (Error e) {
                        warning ("Error while opening log file: %s ...", e.message);
                    }
                });
            });

            button_tags.clicked.connect ( () => {
                add_tag ();
            });

            close_request.connect ( () => {
                // Here we should check for tags file changes and alert user before exit
                if (tags_treeview.ntags > 0 && tags_changed) {
                    var dialog = new Adw.MessageDialog (this, "Tags changed", "There are unsaved changes, discards changes?");
                    dialog.add_response ("cancel", "_Cancel");
                    dialog.add_response ("discard", "_Discard");
                    dialog.set_response_appearance ("discard",Adw.ResponseAppearance.DESTRUCTIVE);
                    dialog.set_default_response ("cancel");
                    dialog.set_close_response ("cancel");
                    dialog.show ();
                    
                    dialog.response.connect ((response) => {
                        if (response == "discard") {
                            this.application.quit ();
                        }
                    });
                    return true;
                } else {
                    return false;
                }
            });
        }
        
        public void set_file (File file) {
            Adw.Toast toast = new Adw.Toast ("Loading file '%s' ...".printf (file.get_basename ()));
            toast.set_timeout (0);
            overlay.add_toast (toast);


            file_opened = file;

            // Sets title for gnome shell window identity
            set_title (file.get_basename ());

            window_title.set_subtitle (file.get_basename ());
            window_title.set_tooltip_text (file.get_path ());
            lines_treeview.set_file (file);

            //this.set_sensitive (false);

            lines_treeview.set_file_ended.connect ( ()=> {
                toast.dismiss ();
                save_tagged_enable ();
                /* Here we check if application property autoload tags is enabled*/
                if (Preferences.instance ().tags_autoload == true) {
                    // load tags for file_chooser_dialog.get_file ()
                    File file_tags = File.new_for_path (file.get_path () + ".tags");
                    set_tags (file_tags, false); 
                }
                count_tag_hits ();
                //this.set_sensitive (true);
            });
        }

        private void add_tag () {
            var tag_dialog = new TagDialogWindow (this.application);

            tag_dialog.added.connect ((tag, add_to_top) => {
                tags_changed = true;

                tag.enable_changed.connect ((enabled) => {
                    lines_treeview.line_store_filter.refilter ();
                });

                tags_treeview.add_tag (tag, add_to_top);

                if (lines_treeview.hide_untagged) { 
                    lines_treeview.line_store_filter.refilter ();
                }
                count_tag_hits ();
            });

            tag_dialog.show ();
        }

        private void remove_all_tags () {
            if (tags_treeview.ntags > 0 && tags_changed) {
                var dialog = new Adw.MessageDialog (this, "Tags changed", "There are unsaved changes, discards changes?");
                dialog.add_response ("cancel", "_Cancel");
                dialog.add_response ("discard", "_Discard");
                dialog.set_response_appearance ("discard",Adw.ResponseAppearance.DESTRUCTIVE);
                dialog.set_response_appearance ("cancel",Adw.ResponseAppearance.SUGGESTED);
                dialog.set_default_response ("cancel");
                dialog.set_close_response ("cancel");
                dialog.show ();
                
                dialog.response.connect ((response) => {
                    if (response == "discard") {
                        tags_changed = false;
                        if (file_tags != null) file_tags = null;
                        tags_treeview.clear_tags ();
                        lines_treeview.line_store_filter.refilter ();
                    }
                });
            } else {
                if (file_tags != null) file_tags = null;
                tags_treeview.clear_tags ();
                lines_treeview.line_store_filter.refilter ();
            }
        }

        private void load_tags () {
            var file_chooser_dialog = new Gtk.FileChooserDialog (
                "Open File", this, Gtk.FileChooserAction.OPEN, 
                "Open", Gtk.ResponseType.ACCEPT, 
                "Cancel", Gtk.ResponseType.CANCEL, 
                null);

            file_chooser_dialog.set_modal (true);

            if (file_opened != null) {
                try {
                    file_chooser_dialog.set_current_folder (file_opened.get_parent ());
                } catch (Error e) {
                    warning ("FileChooser::set_current_folder::error message: %s", e.message);
                }
            }

            file_chooser_dialog.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    file_tags = file_chooser_dialog.get_file ();
                    set_tags(file_tags);
                }
                file_chooser_dialog.destroy ();
            });

            file_chooser_dialog.show ();
        }

        private void set_tags (File file, bool show_ui_dialog = true) {
            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_file (file.get_path ());

                tags_changed = false;
                tags_treeview.clear_tags ();

                Json.Node node = parser.get_root ();
                Json.Array array = new Json.Array ();
                if (node.get_node_type () == Json.NodeType.ARRAY) {
                    array = node.get_array ();
                    array.foreach_element ((array, index_, element_node) => {
                        Tag tag = Json.gobject_deserialize (typeof (Tag), element_node) as Tag;
                        tags_treeview.add_tag (tag);
                        tag.enable_changed.connect ((enabled) => {
                            lines_treeview.line_store_filter.refilter ();
                        });

                        if (lines_treeview.hide_untagged) { 
                            lines_treeview.line_store_filter.refilter ();
                        }
                    });
                }
                count_tag_hits ();
            } catch (Error e) {
                print ("Unable to parse: %s\n", e.message);

                if (show_ui_dialog == false) return;

                var dialog = new Gtk.MessageDialog.with_markup (application.active_window,
                                            Gtk.DialogFlags.DESTROY_WITH_PARENT |
                                            Gtk.DialogFlags.MODAL,
                                            Gtk.MessageType.WARNING,
                                            Gtk.ButtonsType.CLOSE,
                                            "Could not parse tags file");
                //dialog.format_secondary_text (file.get_path ());
                dialog.format_secondary_text (e.message);
                dialog.response.connect ((response_id) => {
                    dialog.destroy ();
                });
                dialog.show ();
            }
        
        }

        private void save_tags () {
            var file_dialog = new Gtk.FileDialog ();
            file_dialog.set_modal (true);
            file_dialog.set_title ("Save tags file");
            file_dialog.set_accept_label ("Save");

            if (file_opened != null) {
                file_dialog.set_initial_folder (file_opened.get_parent ());
                file_dialog.set_initial_name ("%s.tags".printf (file_opened.get_parse_name ()));
            }

            file_dialog.save.begin (this, null, (obj, res) => {
                try {
                    this.tags_treeview.to_file (file_dialog.save.end (res));
                    this.tags_changed = false;
                } catch (Error e) {
                    warning ("Error while saving tags file: %s ...", e.message);
                }
            });
        }

        private void save_tagged_enable () {
            var action = (SimpleAction) lookup_action ("save_tagged");
            action.set_enabled (true);
        }

        private void save_tagged_disable () {
            var action = (SimpleAction) lookup_action ("save_tagged");
            action.set_enabled (false);
        }

        private void save_tagged () {
            var file_dialog = new Gtk.FileDialog ();
            file_dialog.set_modal (true);
            file_dialog.set_title ("Save tagged lines to file");
            file_dialog.set_accept_label ("Save");

            if (file_opened != null) {
                file_dialog.set_initial_folder (file_opened.get_parent ());
                file_dialog.set_initial_name ("%s.tagged".printf (file_opened.get_parse_name ()));
            }

            file_dialog.save.begin (this, null, (obj, res) => {
                try {
                    if (!lines_treeview.hide_untagged) hide_untagged_lines ();
                    lines_treeview.to_file(file_dialog.save.end (res));
                } catch (Error e) {
                    warning ("Error while saving tagged lines to file: %s ...", e.message);
                }
            });
        }

        private void count_tag_hits () {
            Gtk.TreeModel tags;
            Gtk.TreeModel lines;

            tags_treeview.clear_hit_counters ();

            tags = tags_treeview.get_model ();
            lines = (lines_treeview.get_model () as Gtk.TreeModelFilter)?.get_model ();

            lines.foreach ((model, path, iter) => {
                string? line;
                model.@get (iter, LinesTreeView.Columns.LINE_TEXT, out line, -1);
                tags.foreach ((model, path, iter) => {
                    Tag? tag;
                    model.@get (iter, 0, out tag, -1);

                    if (tag.applies_to (line)) {
                        tag.hits += 1;
                    }
                    return false;
                });
                return false;
            });

            tags_treeview.queue_draw ();
        }

        private void hide_untagged_lines () {
            Gtk.TreeIter iter;
            Gtk.TreeModel model;

            lines_treeview.hide_untagged = !lines_treeview.hide_untagged; 

            var action = this.lookup_action ("hide_untagged_lines");
            action.change_state (new Variant.boolean ((bool) lines_treeview.hide_untagged));

            lines_treeview.line_store_filter.refilter ();

            var selection = lines_treeview.get_selection ();
            selection.set_mode (Gtk.SelectionMode.SINGLE);
            if (selection.get_selected (out model, out iter) == true) {
                selection = lines_treeview.get_selection ();
                lines_treeview.scroll_to_cell (model.get_path (iter) , null, true, (float) 0.5, (float) 0.5);
            }
            selection.set_mode (Gtk.SelectionMode.MULTIPLE);
        }

        private void toggle_tags_view () {
            var view_height = paned.get_allocated_height ();
            var action = this.lookup_action ("toggle_tags_view");
            
            if (paned.get_position () >= view_height - 5) {
                paned.set_position ((int) (paned_last_position * view_height));
                action.change_state (new Variant.boolean (false));
            } else {
                paned_last_position = ((float) paned.get_position () / (float) view_height);
                paned.set_position (view_height - 5);
                action.change_state (new Variant.boolean (true));
            }
        }
        
        private void copy () {
            var text = lines_treeview.get_selected_lines_as_string ();
            if (text.length > 0) {
                lines_treeview.get_clipboard ().set_text (text);
            }
        }

        private void toggle_tag_1 () {
            tags_treeview.toggle_tag (0);
        }

        private void toggle_tag_2 () {
            tags_treeview.toggle_tag (1);
        }

        private void toggle_tag_3 () {
            tags_treeview.toggle_tag (2);
        }

        private void toggle_tag_4 () {
            tags_treeview.toggle_tag (3);
        }

        private void toggle_tag_5 () {
            tags_treeview.toggle_tag (4);
        }

        private void toggle_tag_6 () {
            tags_treeview.toggle_tag (5);
        }

        private void toggle_tag_7 () {
            tags_treeview.toggle_tag (6);
        }

        private void toggle_tag_8 () {
            tags_treeview.toggle_tag (7);
        }

        private void toggle_tag_9 () {
            tags_treeview.toggle_tag (8);
        }

        private void toggle_tag_0 () {
            tags_treeview.toggle_tag (9);
        }

        private void only_tag_1 () {
            tags_treeview.tags_set_enable (false);
            toggle_tag_1 ();
        }

        private void only_tag_2 () {
            tags_treeview.tags_set_enable (false);
            toggle_tag_2 ();
        }

        private void only_tag_3 () {
            tags_treeview.tags_set_enable (false);
            toggle_tag_3 ();
        }

        private void only_tag_4 () {
            tags_treeview.tags_set_enable (false);
            toggle_tag_4 ();
        }

        private void only_tag_5 () {
            tags_treeview.tags_set_enable (false);
            toggle_tag_5 ();
        }

        private void only_tag_6 () {
            tags_treeview.tags_set_enable (false);
            toggle_tag_6 ();
        }

        private void only_tag_7 () {
            tags_treeview.tags_set_enable (false);
            toggle_tag_7 ();
        }

        private void only_tag_8 () {
            tags_treeview.tags_set_enable (false);
            toggle_tag_8 ();
        }

        private void only_tag_9 () {
            tags_treeview.tags_set_enable (false);
            toggle_tag_9 ();
        }

        private void only_tag_0 () {
            tags_treeview.tags_set_enable (false);
            toggle_tag_0 ();
        }

        private void enable_all_tags () {
            tags_treeview.tags_set_enable (true);
        }

        private void disable_all_tags () {
            tags_treeview.tags_set_enable (false);
        }

        private void prev_hit () {
            Tag tag;
            string line;
            Gtk.TreeIter iter;
            Gtk.TreeModel model;

            if (lines_treeview.get_number_of_items () == 0 || file_opened == null) {
                return;
            }

            tag = tags_treeview.get_selected_tag ();
            if (tag == null) {
                return;
            }

            if (tag.hits == 0) {
                return;
            }

            var line_selection = lines_treeview.get_selection ();
            line_selection.set_mode (Gtk.SelectionMode.SINGLE);

            if (line_selection.get_selected (out model, out iter) == false) {
                if (model.get_iter_first (out iter) == false) {
                    return;
                } else {
                    line_selection.select_iter (iter);
                }
            }

            for (; model.iter_previous (ref iter);) {
                model.@get (iter, LinesTreeView.Columns.LINE_TEXT, out line);
                if (tag.applies_to (line)) {
                    line_selection.select_iter (iter);
                    lines_treeview.scroll_to_cell (model.get_path (iter), null, true, (float) 0.5, (float) 0.5);
                    break;
                }
            }

            line_selection.set_mode (Gtk.SelectionMode.MULTIPLE);
        }

        private void next_hit () {
            Tag tag;
            string line;
            Gtk.TreeIter iter;
            Gtk.TreeModel model;

            if (lines_treeview.get_number_of_items () == 0 || file_opened == null) {
                return;
            }

            tag = tags_treeview.get_selected_tag ();
            if (tag == null) {
                return;
            }

            if (tag.hits == 0) {
                return;
            }

            var line_selection = lines_treeview.get_selection ();
            line_selection.set_mode (Gtk.SelectionMode.SINGLE);

            if (line_selection.get_selected (out model, out iter) == false) {
                if (model.get_iter_first (out iter) == false) {
                    return;
                } else {
                    line_selection.select_iter (iter);
                }
            }

            for (; model.iter_next (ref iter);) {
                model.@get (iter, LinesTreeView.Columns.LINE_TEXT, out line);
                if (tag.applies_to (line)) {
                    line_selection.select_iter (iter);
                    lines_treeview.scroll_to_cell (model.get_path (iter), null, true, (float) 0.5, (float) 0.5);
                    break;
                }
            }

            line_selection.set_mode (Gtk.SelectionMode.MULTIPLE);
        }
    }
}
