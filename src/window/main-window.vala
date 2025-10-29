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
        unowned Adw.WindowTitle window_title;
        [GtkChild]
        unowned Gtk.Button button_tags_list;
        [GtkChild]
        unowned Gtk.Button button_minimap;
        [GtkChild]
        unowned Adw.ToastOverlay overlay;
        [GtkChild]
        unowned Adw.OverlaySplitView oversplit;
        [GtkChild]
        unowned Gtk.Label title_title;
        [GtkChild]
        unowned Gtk.Label title_focus;

        private Gtk.Stack stack;
        private Adw.BottomSheet bottom_sheet;
        private Gtk.Box main_box;
        private Minimap minimap;
        private Gtk.ScrolledWindow scrolled_tags;
        private Gtk.ScrolledWindow scrolled_lines;
        private Gtk.ScrolledWindow scrolled_minimap;

        private Gtk.Revealer revealer;
        private Tags.ModelMixer mmixer;
        private TagStyleStore style_store;
        private TagStore tags;
        private Lines lines;
        private Tags.Filter filter;
        private Filterer filterer;
        private LinesColumnView lines_colview;
        private File? file_opened = null;
        private File? file_tags = null;
        private bool tags_changed = false;

        private ActionEntry[] WINDOW_ACTIONS = {
            { "action_open_file", action_open_file },
            { "action_toggle_line_number", action_toggle_line_number },
            { "action_add_tag", action_add_tag },
            { "action_remove_all_tags", action_remove_all_tags },
            { "action_load_tags", action_load_tags },
            { "action_import_tags", action_import_tags },
            { "action_save_tags", action_save_tags },
            { "save_tagged", save_tagged },
            { "hide_untagged_lines", hide_untagged_lines, null, "false", null},
            { "toggle_tags_view", toggle_tags_view, null, "false", null},
            { "action_toggle_minimap", action_toggle_minimap, null, "false", null},
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

            style_store = new TagStyleStore ();
            tags = new TagStore (style_store);
            var tags_view = new TagsView (tags.model);

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            box.append (tags_view);

            tags_view.listbox.row_activated.connect ( (r) => {
                var tag = (r as TagRow).tag;
                var tag_dialog =  new TagDialogWindow.for_editing (application, tag);
                tag_dialog.edited.connect ((t) => {
                    tags_changed = true;
                    filter.update ();
                    count_tag_hits ();
                    minimap.set_array (Lines.model_to_array (lines_colview.lines));
                    filter.update ();
                });

                tag_dialog.deleted.connect ((tag) => {
                    tags_changed = true;
                    filter.update ();
                    tags.remove_tag (tag);
                    minimap.set_array (Lines.model_to_array(lines_colview.lines));
                    filter.update ();
                });

                tag_dialog.present ();
            });

            setup_lines_view ();
            setup_minimap (lines_colview.scrolled.get_vadjustment ());
            setup_main_box ();
            setup_buttons ();

            //mmixer = new Tags.ModelMixer (filterer.model, tags);
            mmixer = new Tags.ModelMixer (lines.model, tags);

            var action = this.lookup_action ("toggle_tags_view");
            action.change_state (new Variant.boolean (true));

            stack = new Gtk.Stack ();
            stack.add_named (new WelcomePage (), "welcome");
            stack.add_named (main_box, "main");
            stack.set_visible_child_name ("welcome");

            oversplit.max_sidebar_width = 280;
            oversplit.sidebar = box;
            oversplit.show_sidebar = false;

            oversplit.bind_property ("show-sidebar", window_title, "visible", BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);
            oversplit.bind_property ("show-sidebar", title_focus, "visible", BindingFlags.SYNC_CREATE);

            overlay.set_child (stack);

            var bpc1 = new Adw.BreakpointCondition.length (Adw.BreakpointConditionLengthType.MIN_WIDTH, 575, Adw.LengthUnit.PX);
            var bp = new Adw.Breakpoint (bpc1);
            add_breakpoint (bp);

            bp.apply.connect ( () => {
                oversplit.max_sidebar_width = 280;
                oversplit.min_sidebar_width = 180;
                if (oversplit.show_sidebar) {
                    oversplit.collapsed = false;
                } else {
                    oversplit.collapsed = false;
                    oversplit.show_sidebar = false;
                }
            });

            bp.unapply.connect ( () => {
                oversplit.max_sidebar_width = 180;
                oversplit.min_sidebar_width = 180;
                if (oversplit.show_sidebar) {
                    oversplit.collapsed = true;
                    oversplit.show_sidebar = true;
                } else { 
                    oversplit.collapsed = true;
                    oversplit.show_sidebar = false;
                }
            });

            setup_preferences ();
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
            application.set_accels_for_action("win.action_toggle_minimap", {"<primary>m"});
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

        public bool delegate_line_filter_callback (string? text) {
            var found = false;
            if (text == null) return false;

            for (uint i = 0; i < tags.ntags; i++) {
                var tag = tags.model.get_item (i) as Tag;
                if (tag.applies_to (text) && tag.enabled == true) {
                    return true;
                }
            }
            
            return false;
        }

        private void setup_preferences () {
            var preferences = Preferences.instance ();

            preferences.bind_property("minimap_visible", minimap, "visible", 
                BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
            preferences.bind_property("ln_visible", lines_colview.column_line_number, "visible", 
                BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        }

        private void setup_lines_view () {
            lines = new Lines ();
            filter = new Tags.Filter (tags.model);
            filterer = new Filterer (lines, filter);
            lines_colview = new LinesColumnView (filterer.model);
            lines_colview.column_view.activate.connect ( (p) => {
                var line = lines_colview.lines.get_item (p) as Line;
                var tag_dialog = new TagDialogWindow (this.application, line.text);
                tag_dialog.added.connect ((tag, add_to_top) => {
                    tag.enable_changed.connect ((enabled) => {
                        minimap.set_array (Lines.model_to_array(lines_colview.lines));
                    });
                    tags.add_tag (tag, add_to_top);
                    count_tag_hits ();
                    minimap.set_array (Lines.model_to_array(lines_colview.lines));
                });
                tag_dialog.present ();
            });
        }

        private void setup_scrolled_tags () {
            scrolled_tags = new Gtk.ScrolledWindow ();
            scrolled_tags.set_kinetic_scrolling (true);
            scrolled_tags.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
            scrolled_tags.set_placement (Gtk.CornerType.TOP_LEFT);
            scrolled_tags.set_overlay_scrolling (true);
            scrolled_tags.set_hexpand (true);
            scrolled_tags.set_vexpand (true);
        }

        private void setup_buttons () {
            close_request.connect ( () => {
                if (tags.ntags > 0 && tags_changed) {
                    var dialog = new Adw.AlertDialog ("Tags changed", "There are unsaved changes, discards changes?");
                    dialog.add_response ("cancel", "_Cancel");
                    dialog.add_response ("discard", "_Discard");
                    dialog.set_response_appearance ("discard",Adw.ResponseAppearance.DESTRUCTIVE);
                    dialog.set_default_response ("cancel");
                    dialog.set_close_response ("cancel");
                    dialog.set_prefer_wide_layout (true);
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
            for (uint i = 0; i < tags.model.get_n_items (); i++) {
                var tag = tags.model.get_item (i) as Tag;
                if (tag.enabled && tag.applies_to (text)) {
                    return tag.colors.bg;
                }
            }
            return null;
        }

        private void setup_minimap (Gtk.Adjustment adj) {
            minimap = new Minimap (adj);
            minimap.set_vexpand (true);

            scrolled_minimap = new Gtk.ScrolledWindow();
            scrolled_minimap.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.EXTERNAL);
            scrolled_minimap.set_child (minimap);
            scrolled_minimap.set_vexpand (true);
            //scrolled_minimap.add_css_class ("frame");

            var minimap_manager = new MinimapScrollManager (lines_colview.scrolled, scrolled_minimap);
            minimap.set_line_color_bg_callback (delegate_minimap_bgcolor_getter);
        }

        private void setup_main_box () {
            main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            main_box.append (lines_colview);
            //main_box.append (scrolled_minimap);
            revealer = new Gtk.Revealer ();
            revealer.set_child (scrolled_minimap);
            revealer.set_reveal_child (true);
            revealer.set_transition_duration (1000);
            revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_RIGHT);
            main_box.append (revealer);
        }

        public void open_file (File file) {

            FileType type = file.query_file_type (FileQueryInfoFlags.NONE);
            if (type != FileType.REGULAR) {
                var toast = new Adw.Toast ("'%s' is not a regular file ...".printf(file.get_basename ()));
                toast.set_timeout (3);
                overlay.add_toast (toast);
                return;
            }

            var cancel_open = new Cancellable ();

            lines.from_file.begin (file, cancel_open, (obj, res) => {
                string? err_msg = lines.from_file.end (res);
                if (err_msg == null) {
                    stack.set_visible_child_name ("main");
                    oversplit.show_sidebar = true;
                    file_opened = file;
                    save_tagged_enable ();
                    set_title (file.get_basename ());
                    window_title.set_subtitle (file.get_basename ());
                    window_title.set_tooltip_text (file.get_path ());
                    title_focus.set_label (file.get_basename ());
                    title_focus.set_tooltip_text (file.get_path ());
                    if (Preferences.instance ().tags_autoload == true) {
                        file_tags = File.new_for_path (file.get_path () + ".tags");
                        if (file_tags.query_exists ()) {
                            load_tags_from_file (file_tags);
                            count_tag_hits ();
                        }
                    }
                    count_tag_hits ();
                    minimap.set_array (Lines.model_to_array(lines_colview.lines));
                    for (uint j = 0; j < lines.model.get_n_items (); j++) {
                        var line = lines.model.get_item (j) as Line;
                        for (uint k = 0; k < tags.ntags; k++) {
                            var tag = tags.model.get_item (k) as Tag;
                            if (tag.applies_to (line.text) && tag.enabled) {
                                line.tag = tag;
                                break;
                            }
                        }
                    }
                    filter.update ();
                } else {
                    lines_colview.set_visible (true);
                    show_dialog ("Open File", err_msg, "_Close");
                }
            });
        }

        private void action_add_tag () {
            var tag_dialog = new TagDialogWindow (this.application);

            tag_dialog.added.connect ((tag, add_to_top) => {
                tags_changed = true;

                tags.add_tag (tag, add_to_top);
                tag.changed.connect (() => {
                    for (uint j = 0; j < lines.model.get_n_items (); j++) {
                        var line = lines.model.get_item (j) as Line;
                        for (uint k = 0; k < tags.ntags; k++) {
                            var xtag = tags.model.get_item (k) as Tag;
                            if (xtag.applies_to (line.text) && xtag.enabled) {
                                line.tag = xtag;
                                break;
                            }
                        }
                    }
                    minimap.set_array (Lines.model_to_array(lines_colview.lines));
                    filter.update ();
                });

                count_hits_for_tag (tag);
                minimap.set_array (Lines.model_to_array(lines_colview.lines));
            });

            tag_dialog.show ();
        }

        private void action_remove_all_tags () {
            if (tags.ntags > 0 && tags_changed) {
                var dialog = new Adw.AlertDialog ("Tags changed", "There are unsaved changes, discards changes?");
                dialog.set_prefer_wide_layout (true);
                dialog.add_response ("cancel", "_Cancel");
                dialog.add_response ("discard", "_Discard");
                dialog.set_response_appearance ("discard", Adw.ResponseAppearance.DESTRUCTIVE);
                dialog.set_default_response ("cancel");
                dialog.set_close_response ("cancel");
                dialog.present (this);
                dialog.response.connect ((response) => {
                    if (response == "discard") {
                        tags_remove_all ();
                    }
                });
            } else {
                tags_remove_all ();
            }
        }

        private void tags_remove_all () {
            file_tags = null;
            tags_changed = false;
            tags.remove_all ();
            filter.update ();
            minimap.set_array (Lines.model_to_array(lines_colview.lines));
        }

        private void action_load_tags () {
            UIDialogs.file_open_tags.begin (this, null, (obj, res) => {
                var f = UIDialogs.file_open_tags.end (res);
                if (f != null) load_tags_from_file (f);
            });
        }

        private void action_import_tags () {
            UIDialogs.file_open_tags.begin (this, null, (obj, res) => {
                var f = UIDialogs.file_open_tags.end (res);
                if (f != null) load_tags_from_file (f, true);
            });
        }

        private void load_tags_from_file (File file, bool import = false) {
            tags.from_file.begin  (file, null, import, (obj, res) => {
                tags_changed = false;
                for (int i = 0; i < tags.ntags; i++) {
                    var tag = tags.model.get_object (i) as Tag;
                    tag.changed.connect (() => {
                        minimap.set_array (Lines.model_to_array(lines_colview.lines));
                    });
                }
                minimap.set_array (Lines.model_to_array (lines_colview.lines));
                count_tag_hits ();
                filter.update ();
            });    
        }

        private void action_toggle_line_number () {
            var preferences = Preferences.instance ();
            preferences.ln_visible = !preferences.ln_visible; 
        }
        
        private void action_save_tags () {
            string? suggested_filename = null;
            filter.update ();
            if (file_opened != null) {
                suggested_filename = "%s.tags".printf (file_opened.get_basename ());
            }

            //TagsPersistence.save_tags_file_dialog.begin (this, suggested_filename, null, (obj, res) => {
            UIDialogs.file_save_tags.begin (this, null, suggested_filename, (obj, res) => {
                //var file = TagsPersistence.save_tags_file_dialog.end (res);
                var file = UIDialogs.file_save_tags.end (res);
                if (file != null) {
                    tags.to_file (file);
                    tags_changed = false;
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
            bool revert_hide = false;
            string? suggested_filename = null;

            if (file_opened != null) {
                suggested_filename = "%s.tagged".printf (file_opened.get_basename ());
            }

            UIDialogs.file_save_lines.begin (this, null, suggested_filename, (obj, res) => {
                try {
                    var file = UIDialogs.file_save_lines.end (res);
                    if (file != null) {
                        if (filter.active == false) {
                            hide_untagged_lines ();
                            revert_hide = true;
                        }

                        filterer.to_file.begin (file, (obj, res) => {
                            if (revert_hide == true) hide_untagged_lines ();
                        });
                    }
                } catch (Error e) {
                    warning (e.message);
                    if (e.code != 2) show_dialog ("Save File", e.message);
                }
            });
        }

        private void count_hits_for_tag (Tag t) {
            t.hits = 0;
            for (uint i = 0; i < lines.model.get_n_items (); i++) {
                var line = lines.model.get_item (i) as Line;
                if (t.applies_to (line.text)) {
                    t.hits += 1;
                }
            }
        }

        private void count_tag_hits () {
            tags.hitcounter_reset_all ();
            for (uint i = 0; i < lines.model.get_n_items (); i++) {
                var line = lines.model.get_item (i) as Line;
                for (uint j = 0; j < tags.ntags; j++) {
                    var tag = tags.model.get_item (j) as Tag;
                    if (tag.applies_to (line.text)) {
                        tag.hits += 1;
                    }
                }
            }
        }

        private void hide_untagged_lines () {
            filter.active = !filter.active;

            // Should bind this property !
            var action = this.lookup_action ("hide_untagged_lines");
            action.change_state (new Variant.boolean ((bool) filter.active));

            /*
            if (filterer.model.get_n_items () == 0) {
                inform_user_no_tagged_lines ();
                filter.active = !filter.active;
                action.change_state (new Variant.boolean ((bool) filter.active));
            }
            */

            filter.update ();
            minimap.set_array (Lines.model_to_array(lines_colview.lines));
        }

        private void action_toggle_minimap () {
            //revealer.set_reveal_child (!revealer.get_reveal_child ());
            minimap.set_visible (!minimap.get_visible ());
            var action = this.lookup_action ("action_toggle_minimap");
            action.change_state (new Variant.boolean (minimap.get_visible ()));
        }

        private void toggle_tags_view () {
            oversplit.show_sidebar = !oversplit.show_sidebar;
            var action = this.lookup_action ("toggle_tags_view");
        }
        
        private void copy () {
            var text = lines_colview.get_selected_lines_as_string (); 
            if (text.length > 0) {
                get_clipboard ().set_text (text);
            }
        }

        private void toggle_tag_1 () {
            tags.toggle_tag (0);
        }

        private void toggle_tag_2 () {
            tags.toggle_tag (1);
        }

        private void toggle_tag_3 () {
            tags.toggle_tag (2);
        }

        private void toggle_tag_4 () {
            tags.toggle_tag (3);
        }

        private void toggle_tag_5 () {
            tags.toggle_tag (4);
        }

        private void toggle_tag_6 () {
            tags.toggle_tag (5);
        }

        private void toggle_tag_7 () {
            tags.toggle_tag (6);
        }

        private void toggle_tag_8 () {
            tags.toggle_tag (7);
        }

        private void toggle_tag_9 () {
            tags.toggle_tag (8);
        }

        private void toggle_tag_0 () {
            tags.toggle_tag (9);
        }

        private void only_tag_1 () {
            disable_all_tags ();
            toggle_tag_1 ();
        }

        private void only_tag_2 () {
            disable_all_tags ();
            toggle_tag_2 ();
        }

        private void only_tag_3 () {
            disable_all_tags ();
            toggle_tag_3 ();
        }

        private void only_tag_4 () {
            disable_all_tags ();
            toggle_tag_4 ();
        }

        private void only_tag_5 () {
            disable_all_tags ();
            toggle_tag_5 ();
        }

        private void only_tag_6 () {
            disable_all_tags ();
            toggle_tag_6 ();
        }

        private void only_tag_7 () {
            disable_all_tags ();
            toggle_tag_7 ();
        }

        private void only_tag_8 () {
            disable_all_tags ();
            toggle_tag_8 ();
        }

        private void only_tag_9 () {
            disable_all_tags ();
            toggle_tag_9 ();
        }

        private void only_tag_0 () {
            disable_all_tags ();
            toggle_tag_0 ();
        }

        private void enable_all_tags () {
            tags.set_enable_all (true);
        }

        private void disable_all_tags () {
            tags.set_enable_all (false);
        }

        private void prev_hit () {
            Tag tag = null; //tags_treeview.get_selected_tag ();

            if (tag == null) {
                return;
            }

            if (tag.hits == 0) {
                return;
            }

            var line_selection = lines_colview.selection_model;
            var bitset = line_selection.get_selection ();
            if (bitset.get_size () != 1) {
                message ("Multiple linoes selected ... Can't figure out what to do ...");
                // Maybe choose the first or the **last** from the bitset
                return;
            }
            
            var model = filterer.model; 
            var line  = model.get_item (bitset.get_nth (0)) as Line;
            message ("Got line %zu: %s", line.number, line.text); 
        }

        private void next_hit () {
            Tag tag = null; //tags_treeview.get_selected_tag ();
            if (tag == null) {
                return;
            }

            if (tag.hits == 0) {
                return;
            }

            var line_selection = lines_colview.selection_model;
            var bitset = line_selection.get_selection ();
            if (bitset.get_size () != 1) {
                message ("Multiple linoes selected ... Can't figure out what to do ...");
                // Maybe choose the first or the **last** from the bitset
                return;
            }
            
            var model = filterer.model; 
            var line  = model.get_item (bitset.get_nth (0)) as Line;
            message ("Got line %zu: %s", line.number, line.text); 
            
        }

        private void inform_user_no_tagged_lines () {
            //overlay.dismiss_all ();
            //var toast = new Adw.Toast ("No tags enabled! Showing all lines ...");
            //toast.set_timeout (3);
            //overlay.add_toast (toast);
            hide_untagged_lines ();
        }

        private void show_dialog (string title, string message, string cancel_label = "_Cancel") {
            var dialog = new Adw.AlertDialog (title, message);
            dialog.add_response ("cancel", cancel_label);
            dialog.set_response_appearance ("cancel", Adw.ResponseAppearance.SUGGESTED);
            dialog.set_default_response ("cancel");
            dialog.set_close_response ("cancel");
            dialog.present (this);
        }

        private void action_open_file () {
            UIDialogs.file_open_lines (this, null, (obj, res) => {
                try {
                    File? file = UIDialogs.file_open_lines.end (res);
                    if (file != null) open_file (file);
                } catch (Error e) {
                    if (e.code != 2) {
                        show_dialog ("Open File", "Could not open file...");
                    }
                }
            });
        }
    }
}
