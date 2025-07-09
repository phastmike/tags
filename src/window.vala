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
        
        private Gtk.Box main_box;
        private Gtk.Paned paned;
        private TextMinimap minimap;
        private Gtk.ScrolledWindow scrolled_tags;
        private Gtk.ScrolledWindow scrolled_lines;

        private ulong handler_id;
        private uint scrolled_lines_timeout_id = 0;
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
            setup_actions ();
            setup_minimap ();
            save_tagged_disable ();
            setup_tags_treeview ();     // Also sets assoc scrolled
            setup_lines_treeview ();    // Also sets assoc scrolled
            setup_main_box ();
            setup_paned (main_box, scrolled_tags);
            setup_buttons ();

            var vadj = scrolled_lines.get_vadjustment ();
            vadj.notify["value"].connect (on_scrolled_lines_change);

            minimap.set_viewport_change_callback (on_minimap_change);

            overlay.set_child (paned);
        }

        private int get_default_font_size() {
            var settings = Gtk.Settings.get_default();
            
            string? font_name = null;
            settings.get("gtk-font-name", out font_name);
            
            if (font_name != null) {
                var font_desc = Pango.FontDescription.from_string(font_name);
                int size = font_desc.get_size() / Pango.SCALE;
                return size;
            }
            
            return -1;
        }

        private void on_minimap_change (double position_ratio) {
            // Calculate the absolute scroll position from the ratio
            var vadj = scrolled_lines.get_vadjustment ();
            double document_height = vadj.get_upper() - vadj.get_lower();
            double target = position_ratio * document_height;
            
            // Animate scrolling to the target position
            animate_scroll_to(target);
        }

/*
            int line_height = get_default_font_size ();
            if (line_height > 0) {
                double target = line * line_height;
                animate_scroll_to (target);
            }
        }
*/

        private void animate_scroll_to (double target) {
            var adj = scrolled_lines.get_vadjustment ();
            var current = adj.get_value ();
            double step = (target - current) * 0.3;

            if (Math.fabs (step) < 1) {
                adj.set_value (target);
                return;
            }

            adj.set_value (current + step);

            Timeout.add (16, () => {
                animate_scroll_to (target);
                return false;
            });
        } 

        private void update_minimap_viewport() {
            // Calculate viewport position as ratio
            var vadj = scrolled_lines.get_vadjustment ();
            double document_height = vadj.get_upper() - vadj.get_lower();
            if (document_height <= 0) return;
            
            double start_ratio = vadj.get_value() / document_height;
            double height_ratio = vadj.get_page_size() / document_height;
            
            // Update minimap viewport with pixel ratios
            minimap.set_viewport_ratio(start_ratio, height_ratio);
        }

        private void on_scrolled_lines_change () {
            if (scrolled_lines_timeout_id > 0)  {
                Source.remove (scrolled_lines_timeout_id);
            }

            scrolled_lines_timeout_id = Timeout.add (50, () => {
                update_minimap_viewport();
                scrolled_lines_timeout_id = 0;
                return false;
            });
        }

        private void setup_actions () {
            this.add_action_entries(this.WINDOW_ACTIONS, this);
            application.set_accels_for_action("win.add_tag", {"<primary>n"});
            application.set_accels_for_action("win.save_tagged", {"<primary>s"});
            application.set_accels_for_action("win.hide_untagged_lines", {"<primary>h"});
            application.set_accels_for_action("win.toggle_tags_view", {"<primary>f"});
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
            tags_treeview = new TagsTreeView (this.application);

            tags_treeview.row_activated.connect ((path, column) => {
                Tag tag;
                Gtk.TreeIter iter;

                tags_treeview.get_selection ().get_selected (null, out iter);
                tags_treeview.get_model ().@get (iter, 0, out tag);

                var tag_dialog = new TagDialogWindow.for_editing (this.application, tag);

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

                tag_dialog.present ();
            });

            tags_treeview.no_active_tags.connect ( () => {
                if (lines_treeview.hide_untagged == true) {
                    inform_user_no_tagged_lines ();
                }
            });
            
            setup_scrolled_tags ();
        }

        private void setup_lines_treeview () {
            /* Requires tags_tv model, needs to run afterwards setup_tags... */
            this.lines_treeview = new LinesTreeView (this.application, tags_treeview.get_model ());

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
                        lines_treeview.line_store_filter.refilter ();
                    });
                    tags_treeview.add_tag (tag, add_to_top);
                    count_tag_hits ();
                });

                tag_dialog.show ();
            });

            setup_scrolled_lines ();
        }

        private void setup_scrolled_lines () {
            scrolled_lines = new Gtk.ScrolledWindow ();
            scrolled_lines.set_kinetic_scrolling (true);
            scrolled_lines.set_placement (Gtk.CornerType.TOP_LEFT);
            scrolled_lines.set_overlay_scrolling (true);
            scrolled_lines.set_child (lines_treeview);
            scrolled_lines.set_hexpand (true);
            scrolled_lines.set_vexpand (true);
        }

        private void setup_scrolled_tags () {
            scrolled_tags = new Gtk.ScrolledWindow ();
            scrolled_tags.set_kinetic_scrolling (true);
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
            paned.set_position (this.default_height - 167); // - 47 - 120

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

            // Hack to hide the filter list/taqg list
            // but a better ux to handle tags, is needed
            //paned.set_position (this.default_height);
        }

        private void setup_buttons () {
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
                }

                file_dialog.open.begin (this, null, (obj, res) => {
                    try {
                        var new_file = file_dialog.open.end (res);
                        //file_opened = new_file;
                        this.set_file (new_file);
                    } catch (Error e) {
                        if (e.code != 2) {
                            show_dialog ("Open error", "Could not open file: %s (%d)".printf (e.message, e.code));
                        }
                    }
                });
            });

            button_tags.clicked.connect ( () => {
                add_tag ();
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

        private void setup_minimap () {
            minimap = new TextMinimap ();
            minimap.set_vexpand (true);
        }

        private void setup_main_box () {
            main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            main_box.append (scrolled_lines);
            main_box.append (minimap);
        }

        public void set_file (File file) {
            var spinner = new Gtk.Spinner ();
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

            dialog.set_extra_child (spinner);
            spinner.start ();
            spinner.set_spinning (true);

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
            set_title (file.get_basename ());
            window_title.set_subtitle (file.get_basename ());
            window_title.set_tooltip_text (file.get_path ());

            handler_id = lines_treeview.set_file_ended.connect ( ()=> {
                spinner.set_spinning (false);
                save_tagged_enable ();
                /* Here we check if application property autoload tags is enabled*/
                /* FIXME: What to do if we already have tags inserted, merge or replace? */

                if (Preferences.instance ().tags_autoload == true) {
                    file_tags = File.new_for_path (file.get_path () + ".tags");
                    message("TagsFile: %s", file_tags.get_path ());
                    if (file_tags.query_exists ()) {
                        set_tags (file_tags, cancel_open, false);
                        message("TagsFile: Exists -> Loaded");
                    }

                    if (tags_treeview.ntags > 0) count_tag_hits ();
                }

                button_open_file.set_sensitive (true);
                lines_treeview.disconnect (handler_id);
                dialog.close ();
            });

            // Actual set file 
            // Async with reply via callback set_file_sensitive
            dialog.present (this);
            lines_treeview.set_file (file, cancel_open);
            button_open_file.set_sensitive (false);
            try {
                string contents;
                FileUtils.get_contents (file.get_path (), out contents);
                minimap.load_file (contents);
                
            } catch (FileError e) {
                warning ("%s :: get_contents from file -> Minimap :: Error: %s", GLib.Log.METHOD, e.message);
            }
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
                var dialog = new Adw.AlertDialog ("Tags changed", "There are unsaved changes, discards changes?");
                dialog.add_response ("cancel", "_Cancel");
                dialog.add_response ("discard", "_Discard");
                dialog.set_response_appearance ("discard",Adw.ResponseAppearance.DESTRUCTIVE);
                dialog.set_response_appearance ("cancel",Adw.ResponseAppearance.SUGGESTED);
                dialog.set_default_response ("cancel");
                dialog.set_close_response ("cancel");
                dialog.present (this);
                
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
            var file_dialog = new Gtk.FileDialog ();
            file_dialog.set_title ("Open Tags");
            file_dialog.set_modal (true);

            var filter = new Gtk.FileFilter();
            filter.set_filter_name("Tag files");
            filter.add_mime_type("text/plain");
            filter.add_pattern("*.tags");

            var file_filters = new ListStore (typeof (Gtk.FileFilter));
            file_filters.append (filter);
            file_dialog.set_filters (file_filters);

            if (file_opened != null) {
                file_dialog.set_initial_folder (file_opened.get_parent ());
            }

            file_dialog.open.begin (this, null, (obj, res) => {
                try {
                    var file = file_dialog.open.end (res);
                    set_tags (file);
                } catch (Error e) {
                    warning ("load_tags::error: %s", e.message);
                }
            });
        }

        private void set_tags (File file, Cancellable? cancellable = null, bool show_ui_dialog = true) {
            file.read_async.begin (Priority.DEFAULT, cancellable, (obj, res) => {
                try {
                    FileInputStream stream = file.read_async.end (res);
                    Json.Parser parser = new Json.Parser ();
                    parser.load_from_stream_async.begin (stream, cancellable , (obj, res) => {
                        try{
                            parser.load_from_stream_async.end (res);
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
                                });
                            }
                            lines_treeview.line_store_filter.refilter ();
                            count_tag_hits ();
                        } catch (Error e) {
                            warning ("set_tags::load_from_stream_async_end: %s", e.message);
                        }
                    });
                } catch (Error e) {
                    if (show_ui_dialog == true) {
                        show_dialog ("Load tags", "Could not load the tags file: %s".printf (e.message));
                    }
                }
            });
        }
        
        private void save_tags () {
            var file_dialog = new Gtk.FileDialog ();
            file_dialog.set_modal (true);
            file_dialog.set_title ("Save tags file");
            file_dialog.set_accept_label ("Save");

            if (file_opened != null) {
                //file_dialog.set_initial_folder (file_opened.get_parent ());
                file_dialog.set_initial_name ("%s.tags".printf (file_opened.get_basename ()));
            }

            file_dialog.save.begin (this, null, (obj, res) => {
                try {
                    this.tags_treeview.to_file (file_dialog.save.end (res));
                    this.tags_changed = false;
                } catch (Error e) {
                    show_dialog ("Save Error", "Could not save the tags file: %s".printf (e.message));
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
                //file_dialog.set_initial_folder (file_opened.get_parent ());
                file_dialog.set_initial_name ("%s.tagged".printf (file_opened.get_basename ()));
            }

            file_dialog.save.begin (this, null, (obj, res) => {
                try {
                    if (!lines_treeview.hide_untagged) hide_untagged_lines ();
                    lines_treeview.to_file(file_dialog.save.end (res));
                } catch (Error e) {
                    show_dialog ("Save Error", "Could not save the tagged lines file: %s".printf (e.message));
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

            if (lines_treeview.hide_untagged == true &&
               (tags_treeview.ntags == 0 || tags_treeview.get_n_tags_enabled () == 0)) {
                inform_user_no_tagged_lines ();
            }
        }

        private void toggle_tags_view () {
            var view_height = paned.get_height ();
            //var view_height = paned.get_allocated_height ();
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

            info ("prev_hit start");

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

        private void inform_user_no_tagged_lines () {
            Idle.add ( () => {
                var toast = new Adw.Toast ("No tagged lines, show untagged?");
                toast.set_button_label ("_Show");
                toast.set_timeout (5);
                toast.button_clicked.connect ( () => {
                    hide_untagged_lines ();
                    toast.dismiss ();
                });

                overlay.add_toast (toast);
                return false;
            });
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
