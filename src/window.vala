/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * window.vala
 *
 * Main application Window class
 *
 * José Miguel Fonte
 */

namespace Tagger {
    [GtkTemplate (ui = "/org/ampr/ct1enq/tagger/window.ui")]
    public class Window : Gtk.ApplicationWindow {
        [GtkChild]
        unowned Gtk.Button button_open_file;
        [GtkChild]
        unowned Gtk.Button button_tags;
        [GtkChild]
        unowned Gtk.Label subtitle;
        
        private Gtk.Paned paned;
        private LinesTreeView lines_treeview;
        private TagsTreeView tags_treeview;
        private double paned_last_position = 0.778086;
        private File? file_opened = null;

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
            { "disable_all_tags", disable_all_tags }
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
                tag_dialog.added.connect ((tag) => {
                    tag.enable_changed.connect ((enabled) => {
                        lines_treeview.line_store_filter.refilter ();
                    });
                    tags_treeview.add_tag (tag);
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
                    if (lines_treeview.hide_untagged) 
                        lines_treeview.line_store_filter.refilter ();
                    count_tag_hits ();
                });

                tag_dialog.deleted.connect ((tag) => {
                    tags_treeview.remove_tag (tag);
                    if (lines_treeview.hide_untagged) { 
                        lines_treeview.line_store_filter.refilter ();
                    }
                });

                tag_dialog.show ();
            });

            paned = new Gtk.Paned (Gtk.Orientation.VERTICAL);
            set_child (paned);

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

                file_chooser_dialog.response.connect ( (response_id) => {
                    if (response_id == Gtk.ResponseType.ACCEPT) {
                        this.set_file(file_chooser_dialog.get_file ());
                    }
                    file_chooser_dialog.destroy ();
                });

                file_chooser_dialog.show ();
            });

            button_tags.clicked.connect ( () => {
                add_tag ();
            });

            close_request.connect ( () => {
                // Here we should check for tags file changes and alert user before exit
                print ("I'm about the exit from tagger ...\n");
                return false;
            });
        }
        
        public void set_file (File file) {
            file_opened = file;
            // Sets title for gnome shell window identity
            set_title (file.get_basename ());

            subtitle.set_label (file.get_basename ());
            subtitle.set_tooltip_text (file.get_path ());
            lines_treeview.set_file (file.get_path ());
            save_tagged_enable ();

            /* Here we check if application property autoload tags is enabled*/
            if (Preferences.instance ().tags_autoload == true) {
                // load tags for file_chooser_dialog.get_file ()
                File file_tags = File.new_for_path (file.get_path () + ".tags");
                set_tags (file_tags, false); 
            }
        }

        private void add_tag () {
            var tag_dialog = new TagDialogWindow (this.application);

            tag_dialog.added.connect ((tag) => {

                tag.enable_changed.connect ((enabled) => {
                    lines_treeview.line_store_filter.refilter ();
                });

                tags_treeview.add_tag (tag);

                if (lines_treeview.hide_untagged) { 
                    lines_treeview.line_store_filter.refilter ();
                }
                count_tag_hits ();
            });

            tag_dialog.show ();
        }

        private void remove_all_tags () {
            tags_treeview.clear_tags ();
            lines_treeview.line_store_filter.refilter ();
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

            file_chooser_dialog.response.connect ( (response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    set_tags(file_chooser_dialog.get_file ());
                }
                file_chooser_dialog.destroy ();
            });

            file_chooser_dialog.show ();
        }

        private void set_tags (File file, bool show_ui_dialog = true) {
            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_file (file.get_path ());

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
            var file_chooser_dialog = new Gtk.FileChooserDialog (
                "Save File", this, Gtk.FileChooserAction.SAVE, 
                "Save", Gtk.ResponseType.ACCEPT, 
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

            file_chooser_dialog.response.connect ( (response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    var file = file_chooser_dialog.get_file ();
                    //lines_treeview.to_file(file);
                    tags_treeview.to_file (file);
                }
                file_chooser_dialog.destroy ();
            });

            file_chooser_dialog.show ();
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
            var file_chooser_dialog = new Gtk.FileChooserDialog (
                "Save File", this, Gtk.FileChooserAction.SAVE, 
                "Save", Gtk.ResponseType.ACCEPT, 
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

            file_chooser_dialog.response.connect ( (response_id) => {
                if (response_id == Gtk.ResponseType.ACCEPT) {
                    var file = file_chooser_dialog.get_file ();
                    lines_treeview.to_file(file);
                }
                file_chooser_dialog.destroy ();
            });

            file_chooser_dialog.show ();
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
                    if (line.contains (tag.pattern)) {
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
    }
}
