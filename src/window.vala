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
        private FiltersTreeView filters_treeview;
        private double paned_last_position = 0.778086;
        private File? last_file = null;

        private ActionEntry[] WINDOW_ACTIONS = {
            { "add_tag", add_tag },
            { "hide_untagged_lines", hide_untagged_lines, null, "false", null},
            { "toggle_filters_view", toggle_filters_view, null, "false", null}
        };

        public Window (Gtk.Application app) {
            Object (application: app);

            this.add_action_entries(this.WINDOW_ACTIONS, this);
            app.set_accels_for_action("win.add_tag", {"<primary>n"});
            app.set_accels_for_action("win.hide_untagged_lines", {"<primary>h"});
            app.set_accels_for_action("win.toggle_filters_view", {"<primary>f"});
            
            filters_treeview = new FiltersTreeView (app);
            lines_treeview = new LinesTreeView (app, filters_treeview.get_model () as Gtk.ListStore);
            
            lines_treeview.row_activated.connect ((path, column) => {
                string line_text;
                Gtk.TreeIter iter;
                FilterDialogWindow filter_dialog;

                lines_treeview.get_selection ().get_selected (null, out iter);
                lines_treeview.get_model ().@get (iter, LinesTreeView.Columns.LINE_TEXT, out line_text, -1);

                filter_dialog = new FilterDialogWindow (app, line_text);
                filter_dialog.added.connect ((filter) => {
                    filter.enable_changed.connect ((enabled) => {
                        lines_treeview.line_store_filter.refilter ();
                    });
                    filters_treeview.add_filter (filter);
                    count_tag_hits ();
                });

                filter_dialog.show ();
            });

            
            filters_treeview.row_activated.connect ((path, column) => {
                LineFilter filter;
                Gtk.TreeIter iter;

                filters_treeview.get_selection ().get_selected (null, out iter);
                filters_treeview.get_model ().@get (iter, 0, out filter);

                var filter_dialog = new FilterDialogWindow.for_editing (app, filter);

                filter_dialog.edited.connect ((filter) => {
                    count_tag_hits ();
                });
                /* Use Dialog and Response (reuse) or leave it as is */
                filter_dialog.deleted.connect ((filter) => {
                    filters_treeview.get_model ().foreach ((model, path, iter) => {
                        LineFilter lf;
                        model.@get (iter, 0, out lf);

                        if (lf == filter) {
                            ((Gtk.ListStore) model).remove (ref iter);
                            return true;
                        } else {
                            return false;
                        }
                    });
                });

                filter_dialog.show ();
            });

            paned = new Gtk.Paned (Gtk.Orientation.VERTICAL);
            set_child (paned);

            paned.notify["position"].connect ((s,p) => {
                var view_height = paned.get_allocated_height ();
                
                if (view_height == 0) return;

                var action = this.lookup_action ("toggle_filters_view");

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

            var scrolled_filters = new Gtk.ScrolledWindow ();
            scrolled_filters.set_kinetic_scrolling (true);
            scrolled_filters.set_placement (Gtk.CornerType.TOP_LEFT);
            scrolled_filters.set_overlay_scrolling (true);
            scrolled_filters.set_child (filters_treeview);

            paned.set_start_child (scrolled_lines);
            paned.set_end_child (scrolled_filters);
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

                if (last_file != null) {
                    try {
                        file_chooser_dialog.set_current_folder (last_file.get_parent ());
                    } catch (Error e) {
                        warning ("FileChooser::set_current_folder::error message: %s", e.message);
                    }
                }

                file_chooser_dialog.response.connect ( (response_id) => {
                    if (response_id == Gtk.ResponseType.ACCEPT) {
                        last_file = file_chooser_dialog.get_file ();
                        //message ("last_file = %s\n", last_file.get_path ());
                        this.set_file(last_file);
                    }
                    file_chooser_dialog.destroy ();
                });

                file_chooser_dialog.show ();
            });

            button_tags.clicked.connect ( () => {
                add_tag ();
            });
        }
        
        public void set_file (File file) {
            // Sets title for gnome shell window identity
            set_title (file.get_basename ());

            subtitle.set_label (file.get_basename ());
            subtitle.set_tooltip_text (file.get_path ());
            lines_treeview.set_file (file.get_path ());
        }

        private void add_tag () {
            var filter_dialog_window = new FilterDialogWindow (this.application);
            filter_dialog_window.show ();

            filter_dialog_window.added.connect ((filter) => {

                filter.enable_changed.connect ((enabled) => {
                    lines_treeview.line_store_filter.refilter ();
                });

                filters_treeview.add_filter (filter);
                count_tag_hits ();
            });
        }

        private void count_tag_hits () {
            Idle.add (() => {
                Gtk.TreeModel tags;
                Gtk.TreeModel lines;

                filters_treeview.clear_hit_counters ();

                tags = filters_treeview.get_model ();
                lines = lines_treeview.get_model ();

                lines.foreach ((model, path, iter) => {
                    string? line;
                    model.@get (iter, LinesTreeView.Columns.LINE_TEXT, out line, -1);
                    tags.foreach ((model, path, iter) => {
                        LineFilter? tag;
                        model.@get (iter, 0, out tag, -1);
                        if (line.contains (tag.pattern)) tag.hits += 1;
                        return false;
                    });
                    return false;
                });

                filters_treeview.queue_draw ();
                return false;
            });
        }

        private void hide_untagged_lines () {
            Gtk.TreeIter iter;
            Gtk.TreeModel model;

            lines_treeview.hide_untagged = !lines_treeview.hide_untagged; 

            var action = this.lookup_action ("hide_untagged_lines");
            action.change_state (new Variant.boolean ((bool) lines_treeview.hide_untagged));

            lines_treeview.line_store_filter.refilter ();

            var selection = lines_treeview.get_selection ();
            if (selection.get_selected (out model, out iter) == true) {
                selection = lines_treeview.get_selection ();
                lines_treeview.scroll_to_cell (model.get_path (iter) , null, true, (float) 0.5, (float) 0.5);
            }
        }

        private void toggle_filters_view () {
            var view_height = paned.get_allocated_height ();
            var action = this.lookup_action ("toggle_filters_view");
            
            if (paned.get_position () >= view_height - 5) {
                paned.set_position ((int) (paned_last_position * view_height));
                action.change_state (new Variant.boolean (false));
            } else {
                paned_last_position = ((float) paned.get_position () / (float) view_height);
                paned.set_position (view_height - 5);
                action.change_state (new Variant.boolean (true));
            }
        }
    }
}
