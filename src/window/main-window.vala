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
    [GtkTemplate (ui = "/io/github/phastmike/tags/ui/main-window.ui")]
    public class MainWindow : Adw.ApplicationWindow {
        [GtkChild]
        unowned Gtk.Button button_open_file;
        [GtkChild]
        unowned Adw.SplitButton button_tags;
        [GtkChild]
        unowned Adw.WindowTitle window_title;
        [GtkChild]
        unowned Adw.ToastOverlay overlay;

        private Gtk.Box main_box;
        private Gtk.Paned paned;
        private Minimap minimap;
        private Gtk.ScrolledWindow scrolled_tags;
        private Gtk.ScrolledWindow scrolled_lines;
        private Gtk.ScrolledWindow scrolled_minimap;

        private ulong handler_id;
        private LinesTreeView lines_treeview;
        private TagsTreeView tags_treeview;
        private double paned_last_position = 0.778086;
        private File? file_opened = null;
        private File? file_tags = null;
        private bool tags_changed = false;

        private ActionEntry[] WINDOW_ACTIONS = {
            { "action_toggle_line_number", action_toggle_line_number },
            { "action_add_tag", action_add_tag },
            { "action_remove_all_tags", action_remove_all_tags },
            { "action_load_tags", action_load_tags },
            { "action_save_tags", action_save_tags },
            { "save_tagged", save_tagged },
            { "hide_untagged_lines", hide_untagged_lines, null, "false", null},
            { "toggle_tags_view", toggle_tags_view, null, "false", null},
            { "toggle_minimap", toggle_minimap, null, "false", null},
            { "copy", copy },
            { "toggle_tag_1", toggle_tag_1 },
            { "toggle_tag_2", toggle_tag_2 },
            { "toggle_tag_3", toggle_tag_3 },
            { "toggle_tag_4", toggle_tag_4 },
            { "toggle_tag_5", toggle_tag_5 },
            { "toggle_tag_6", toggle_tag_6 },
            { "toggle_tag_7", toggle_tag_7 },
            { "toggle_tag_8", toggle_tag_8 },
            { "toggle_tag_9", toggle_tag_9 },
            { "toggle_tag_0", toggle_tag_0 },
            { "only_tag_1", only_tag_1 },
            { "only_tag_2", only_tag_2 },
            { "only_tag_3", only_tag_3 },
            { "only_tag_4", only_tag_4 },
            { "only_tag_5", only_tag_5 },
            { "only_tag_6", only_tag_6 },
            { "only_tag_7", only_tag_7 },
            { "only_tag_8", only_tag_8 },
            { "only_tag_9", only_tag_9 },
            { "only_tag_0", only_tag_0 },
            { "enable_all_tags", enable_all_tags },
            { "disable_all_tags", disable_all_tags },
            { "prev_hit", prev_hit },
            { "next_hit", next_hit }
        };

        public MainWindow (Gtk.Application app) {
            Object (application: app);
            setup_actions ();
            save_tagged_disable ();
            setup_tags_treeview ();
            setup_lines_treeview ();
            setup_minimap (scrolled_lines.get_vadjustment ());
            setup_main_box ();
            setup_paned (main_box, scrolled_tags);
            setup_buttons ();

            overlay.set_child (paned);
        }

        // Override the size_allocate method
        // To force the minimap to redraw the widget
        // Not sure why the adjustment changed doesnt trigger a draw
        // FIXME: Dig on why!
        public override void size_allocate (int a, int b, int c) {
            base.size_allocate (a, b, c);
            minimap.queue_draw ();
        }

        private void setup_actions () {
            this.add_action_entries(this.WINDOW_ACTIONS, this);
            application.set_accels_for_action("win.action_toggle_line_number", {"<primary>l"});
            application.set_accels_for_action("win.action_add_tag", {"<primary>n"});
            application.set_accels_for_action("win.save_tagged", {"<primary>s"});
            application.set_accels_for_action("win.hide_untagged_lines", {"<primary>h"});
            application.set_accels_for_action("win.toggle_tags_view", {"<primary>f"});
            application.set_accels_for_action("win.toggle_minimap", {"<primary>m"});
            application.set_accels_for_action("win.copy", {"<primary>c"});
            application.set_accels_for_action("win.toggle_tag_1", {"<alt>1"});
            application.set_accels_for_action("win.toggle_tag_2", {"<alt>2"});
            application.set_accels_for_action("win.toggle_tag_3", {"<alt>3"});
            application.set_accels_for_action("win.toggle_tag_4", {"<alt>4"});
            application.set_accels_for_action("win.toggle_tag_5", {"<alt>5"});
            application.set_accels_for_action("win.toggle_tag_6", {"<alt>6"});
            application.set_accels_for_action("win.toggle_tag_7", {"<alt>7"});
            application.set_accels_for_action("win.toggle_tag_8", {"<alt>8"});
            application.set_accels_for_action("win.toggle_tag_9", {"<alt>9"});
            application.set_accels_for_action("win.toggle_tag_0", {"<alt>0"});
            application.set_accels_for_action("win.only_tag_1", {"<primary>1"});
            application.set_accels_for_action("win.only_tag_2", {"<primary>2"});
            application.set_accels_for_action("win.only_tag_3", {"<primary>3"});
            application.set_accels_for_action("win.only_tag_4", {"<primary>4"});
            application.set_accels_for_action("win.only_tag_5", {"<primary>5"});
            application.set_accels_for_action("win.only_tag_6", {"<primary>6"});
            application.set_accels_for_action("win.only_tag_7", {"<primary>7"});
            application.set_accels_for_action("win.only_tag_8", {"<primary>8"});
            application.set_accels_for_action("win.only_tag_9", {"<primary>9"});
            application.set_accels_for_action("win.only_tag_0", {"<primary>0"});
            application.set_accels_for_action("win.enable_all_tags", {"<alt>e"});
            application.set_accels_for_action("win.disable_all_tags", {"<alt>d"});
            application.set_accels_for_action("win.prev_hit", {"F2"});
            application.set_accels_for_action("win.next_hit", {"F3"});
        }

        private void setup_tags_treeview () {
            tags_treeview = new TagsTreeView ();

            tags_treeview.get_model ().row_changed.connect ( () => {
                minimap.set_array (lines_treeview.model_to_array ());
            });

            tags_treeview.get_model ().row_inserted.connect ( () => {
                lines_treeview.queue_draw ();
                minimap.set_array (lines_treeview.model_to_array ());
            });

            tags_treeview.row_activated.connect ((path, column) => {
                Tag tag;
                Gtk.TreeIter iter;

                tags_treeview.get_selection ().get_selected (null, out iter);
                tags_treeview.get_model ().@get (iter, 0, out tag);

                var tag_dialog = new TagDialogWindow.for_editing (this.application, tag);

                tag_dialog.edited.connect ((t) => {
                    tags_changed = true;
                    count_tag_hits ();
                    lines_treeview.refilter ();
                    minimap.set_array (lines_treeview.model_to_array ());
                });

                tag_dialog.deleted.connect ((tag) => {
                    tags_changed = true;
                    tags_treeview.remove_tag (tag);
                    lines_treeview.refilter ();
                    minimap.set_array (lines_treeview.model_to_array ());
                });

                tag_dialog.present ();
            });

            tags_treeview.no_active_tags.connect ( () => {
                if (lines_treeview.hide_untagged == true) {
                    inform_user_no_tagged_lines ();
                }
        });

            setup_scrolled_tags ();
        }

        public bool delegate_line_filter_callback (string? text) {
            var found = false;
            if (text == null) return false;
            if (tags_treeview == null) return false;
            var tags = tags_treeview.get_model ();
            if (tags == null) return false;
            tags.foreach ((tags_model, tag_path, tag_iter) => {
                Tag tag;

                tags_model.@get (tag_iter, 0, out tag);

                if (tag.applies_to (text) && tag.enabled) {
                    found = true;
                }

                return found;
            });
            return found;
        }

        public void delegate_treeview_cell_color_callback (string text, Gtk.CellRendererText cell) {
            Gdk.RGBA? bg_color = tags_treeview.get_bg_color_for_text (text);
            Gdk.RGBA? fg_color = tags_treeview.get_fg_color_for_text (text);
            if (bg_color != null) cell.background_rgba = bg_color;
            if (fg_color != null) cell.foreground_rgba = fg_color;
        }

        private void setup_lines_treeview () {
            this.lines_treeview = new LinesTreeView ();
            lines_treeview.delegate_line_filter_set (delegate_line_filter_callback);
            lines_treeview.delegate_line_color_set (delegate_treeview_cell_color_callback);

            lines_treeview.cleared.connect ( () => {
                minimap.clear ();
            });

            lines_treeview.row_activated.connect ((path, column) => {
                string line_text;
                Gtk.TreeIter iter;

                var selection = lines_treeview.get_selection ();
                selection.set_mode (Gtk.SelectionMode.SINGLE);
                selection.get_selected (null, out iter);
                lines_treeview.get_model ().@get (iter, LinesTreeView.Columns.LINE_TEXT, out line_text, -1);
                selection.set_mode (Gtk.SelectionMode.MULTIPLE);

                var tag_dialog = new TagDialogWindow (this.application, line_text);
                tag_dialog.added.connect ((tag, add_to_top) => {
                    tag.enable_changed.connect ((enabled) => {
                        lines_treeview.refilter ();
                        minimap.set_array (lines_treeview.model_to_array ());
                    });
                    tags_treeview.add_tag (tag, add_to_top);
                    count_tag_hits ();
                    minimap.set_array (lines_treeview.model_to_array ());
                });

                tag_dialog.show ();
            });


            setup_preference_lines_changes (lines_treeview);
            setup_scrolled_lines ();
        }

        // FIXME: WIP refactoring
        // Decoupling preferences from lines-treeview
        // Should be tweaking the preferences or only the session?
        private void setup_preference_lines_changes (LinesTreeView treeview) {
            var preferences = Preferences.instance ();

            preferences.line_number_visibility_changed.connect ( (v) => {
                treeview.set_line_number_visibility (v);
            });

            preferences.line_number_color_fg_changed.connect ( (c) => {
                treeview.set_linen_number_color_fg (c);
            });

            preferences.line_number_color_bg_changed.connect ( (c) => {
                treeview.set_linen_number_color_bg (c);
            });

            treeview.set_line_number_visibility (preferences.ln_visible);
            treeview.set_linen_number_color_fg (preferences.ln_fg_color);
            treeview.set_linen_number_color_bg (preferences.ln_bg_color);
        }

        private void setup_scrolled_lines () {
            scrolled_lines = new Gtk.ScrolledWindow ();
            scrolled_lines.set_kinetic_scrolling (true);
            // Use PolicyType EXTERNAL to hide the scroll from the treeview
            scrolled_lines.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
            scrolled_lines.set_placement (Gtk.CornerType.TOP_LEFT);
            scrolled_lines.set_overlay_scrolling (true);
            scrolled_lines.set_child (lines_treeview);
            scrolled_lines.set_hexpand (true);
            scrolled_lines.set_vexpand (true);
        }

        private void setup_scrolled_tags () {
            scrolled_tags = new Gtk.ScrolledWindow ();
            scrolled_tags.set_kinetic_scrolling (true);
            scrolled_tags.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
            scrolled_tags.set_placement (Gtk.CornerType.TOP_LEFT);
            scrolled_tags.set_overlay_scrolling (true);
            scrolled_tags.set_child (tags_treeview);
            scrolled_tags.set_hexpand (true);
            scrolled_tags.set_vexpand (true);
        }

        private void setup_paned (Gtk.Widget top, Gtk.Widget bottom) {
            paned = new Gtk.Paned (Gtk.Orientation.VERTICAL);

            paned.set_start_child (top);
            paned.set_end_child (bottom);
            paned.set_resize_start_child (true);
            paned.set_resize_end_child (true);
            paned.set_wide_handle (true);
            paned.set_position (this.default_height - 167);

            // Hack to hide the filter list/taqg list
            // but a better ux to handle tags, is needed
            //paned.set_position (this.default_height);

            paned.notify["position"].connect ((s,p) => {
                var view_height = paned.get_height ();
                
                if (view_height == 0) return;

                var action = this.lookup_action ("toggle_tags_view");

                /* Change menu action state if manually hidden */
                if (paned.get_position () >= view_height - 5) {
                    action.change_state (new Variant.boolean (true));
                } else {
                    action.change_state (new Variant.boolean (false));
                }
            });
        }

        private void setup_buttons () {
            button_open_file.clicked.connect ( () => {
                var persistence = new LinesPersistence ();
                persistence.open_lines_file_dialog.begin (this, null, (obj, res) => {
                    File? file = persistence.open_lines_file_dialog.end (res);
                    if (file != null) open_file (file);
                });
            });

            button_tags.clicked.connect ( () => {
                action_add_tag ();
            });

            close_request.connect ( () => {
                if (tags_treeview.ntags > 0 && tags_changed) {
                    var dialog = new Adw.AlertDialog ("Tags changed", "There are unsaved changes, discards changes?");
                    dialog.add_response ("cancel", "_Cancel");
                    dialog.add_response ("discard", "_Discard");
                    dialog.set_response_appearance ("discard",Adw.ResponseAppearance.DESTRUCTIVE);
                    dialog.set_default_response ("cancel");
                    dialog.set_close_response ("cancel");
                    dialog.present (this);
                    
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

        private Gdk.RGBA? delegate_minimap_bgcolor_getter (string? text) {
            return tags_treeview.get_bg_color_for_text (text);
        }

        private void setup_minimap (Gtk.Adjustment adj) {
            minimap = new Minimap (adj);
            minimap.set_vexpand (true);

            scrolled_minimap = new Gtk.ScrolledWindow();
            scrolled_minimap.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.EXTERNAL);
            scrolled_minimap.set_child (minimap);
            scrolled_minimap.set_vexpand (true);

            var minimap_manager = new MinimapScrollManager (scrolled_lines, scrolled_minimap);
            minimap.set_line_color_bg_callback (delegate_minimap_bgcolor_getter);
        }

        private void setup_main_box () {
            main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            main_box.append (scrolled_lines);
            main_box.append (scrolled_minimap);
        }

        public void open_file (File file) {
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
                /* Here we check if application property autoload tags is enabled*/
                /* FIXME: What to do if we already have tags inserted, merged or replace? */

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
                    /* Here we check if application property autoload tags is enabled*/
                    /* FIXME: What to do if we already have tags inserted, merged or replace? */

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

        private void action_add_tag () {
            var tag_dialog = new TagDialogWindow (this.application);

            tag_dialog.added.connect ((tag, add_to_top) => {
                tags_changed = true;

                tag.enable_changed.connect ((enabled) => {
                    lines_treeview.refilter ();
                    minimap.set_array (lines_treeview.model_to_array ());
                });

                tags_treeview.add_tag (tag, add_to_top);

                if (lines_treeview.hide_untagged) { 
                    lines_treeview.refilter ();
                    minimap.set_array (lines_treeview.model_to_array ());
                }

                count_tag_hits ();
                minimap.set_array (lines_treeview.model_to_array ());
            });

            tag_dialog.show ();
        }

        private void action_remove_all_tags () {
            if (tags_treeview.ntags > 0 && tags_changed) {
                var dialog = new Adw.AlertDialog ("Tags changed", "There are unsaved changes, discards changes?");
                dialog.add_response ("cancel", "_Cancel");
                dialog.add_response ("discard", "_Discard");
                dialog.set_response_appearance ("discard", Adw.ResponseAppearance.DESTRUCTIVE);
                dialog.set_response_appearance ("cancel", Adw.ResponseAppearance.SUGGESTED);
                dialog.set_default_response ("cancel");
                dialog.set_close_response ("cancel");
                dialog.present (this);
                
                dialog.response.connect ((response) => {
                    if (response == "discard") {
                        tags_changed = false;
                        tags_remove_all ();
                    }
                });
            } else {
                tags_remove_all ();
            }
        }

        private void tags_remove_all () {
            if (file_tags != null) file_tags = null;
            tags_treeview.clear_tags ();
            lines_treeview.refilter ();
            minimap.set_array (lines_treeview.model_to_array ());
        }

        private void action_load_tags () {
            load_tags_from_file ();
        }

        private void load_tags_from_file (File? file = null) {
            var persistence = new TagsPersistence ();

            persistence.loaded_from_file.connect ( (tags) => {
                tags_changed = false;
                tags_treeview.clear_tags ();
                for (int i = 0; i < tags.n_items; i++) {
                    Tag tag = (Tag) tags.get_object (i);
                    tags_treeview.add_tag (tag);

                    tag.enable_changed.connect ((enabled) => {
                        lines_treeview.refilter ();
                        minimap.set_array (lines_treeview.model_to_array ());
                    });
                }
                lines_treeview.refilter ();
                minimap.set_array (lines_treeview.model_to_array ());
                count_tag_hits ();
            });

            if (file == null) {
                persistence.open_tags_file_dialog (this);
            } else {
                persistence.from_file (file);
            }
        }

        private void action_toggle_line_number () {
            var preferences = Preferences.instance ();
            preferences.ln_visible = !preferences.ln_visible; 
        }
        
        private void action_save_tags () {
            var persistance = new TagsPersistence ();
            persistance.saved_to_file.connect ( (file) => {
                tags_changed = false;
            });
            persistance.save_tags_file_dialog (tags_treeview.get_model ());
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
                //file_dialog.set_initial_folder (file_opened.get_parent ());
                file_dialog.set_initial_name ("%s.tagged".printf (file_opened.get_basename ()));
            }

            file_dialog.save.begin (this, null, (obj, res) => {
                try {
                    if (!lines_treeview.hide_untagged) hide_untagged_lines ();
                    lines_treeview.to_file(file_dialog.save.end (res));
                } catch (Error e) {
                    message (e.message);
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

            // Should bind this property !
            var action = this.lookup_action ("hide_untagged_lines");
            action.change_state (new Variant.boolean ((bool) lines_treeview.hide_untagged));

            lines_treeview.refilter ();

            var selection = lines_treeview.get_selection ();
            selection.set_mode (Gtk.SelectionMode.SINGLE);

            if (lines_treeview.hide_untagged == true &&
               (tags_treeview.ntags == 0 || tags_treeview.get_n_tags_enabled () == 0)) {
                inform_user_no_tagged_lines ();
            }

            minimap.set_array (lines_treeview.model_to_array ());

            if (selection.get_selected (out model, out iter) == true) {
                selection = lines_treeview.get_selection ();
                lines_treeview.scroll_to_cell (model.get_path (iter) , null, true, (float) 0.5, (float) 0.5);
            }

            // FIXME: Hack to force the viewport to recenter
            // does not work very well ...
            var vadj_value = scrolled_lines.get_vadjustment ().get_value ();
            scrolled_lines.get_vadjustment ().set_value (vadj_value + 1.0);
            selection.set_mode (Gtk.SelectionMode.MULTIPLE);
        }

        private void toggle_minimap () {
            var action = this.lookup_action ("toggle_minimap");
            action.change_state (new Variant.boolean (minimap.get_visible ()));
            minimap.set_visible (!minimap.get_visible ());
        }

        private void toggle_tags_view () {
            var view_height = paned.get_height ();
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

            if (lines_treeview.get_number_of_items () == 0) {
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

            if (lines_treeview.get_number_of_items () == 0) {
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

            for (; model.iter_next (ref iter) ;) {
                model.@get (iter, LinesTreeView.Columns.LINE_TEXT, out line);
                if (tag.applies_to (line)) {
                    line_selection.select_iter (iter);
                    lines_treeview.scroll_to_cell (model.get_path (iter), null, true, (float) 0.5, (float) 0.5);
                    break;
                }
            }

            line_selection.set_mode (Gtk.SelectionMode.MULTIPLE);
        }

        private void inform_user_no_tagged_lines () {
            overlay.dismiss_all ();
            var toast = new Adw.Toast ("No tags enabled!..");
            toast.set_timeout (5);
            overlay.add_toast (toast);
            hide_untagged_lines ();
        }

        private void show_dialog (string title, string message) {
            var dialog = new Adw.AlertDialog (title, message);
            dialog.add_response ("cancel", "_Cancel");
            dialog.set_default_response ("cancel");
            dialog.set_close_response ("cancel");
            dialog.present (this);
        }
    }
}
