/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * filters-tree-view.vala
 *
 * Extended Gtk.TreeView as FiltersTreeView
 *
 * José Miguel Fonte
 */

namespace Tagger {
    [GtkTemplate (ui = "/org/ampr/ct1enq/tagger/filters-tree-view.ui")]
    public class FiltersTreeView : Gtk.TreeView {
        [GtkChild]
        private unowned Gtk.ListStore filter_store;
        [GtkChild]
        private unowned Gtk.TreeViewColumn col_filter_checkbox;
        [GtkChild]
        private unowned Gtk.TreeViewColumn col_filter_pattern;
        [GtkChild]
        private unowned Gtk.TreeViewColumn col_filter_description;
        [GtkChild]
        private unowned Gtk.TreeViewColumn col_filter_hits;
        [GtkChild]
        private unowned Gtk.CellRendererToggle renderer_filter_checkbox;
        [GtkChild]
        private unowned Gtk.CellRendererText renderer_filter_pattern;
        [GtkChild]
        private unowned Gtk.CellRendererText renderer_filter_description;
        [GtkChild]
        private unowned Gtk.CellRendererText renderer_filter_hits;

        public FiltersTreeView (Gtk.Application app) {
            setup_cell_renderers ();
            
            renderer_filter_checkbox.toggled.connect ((path) => {
                Gtk.TreeIter i;
                LineFilter filter;
                filter_store.get_iter_from_string (out i, path);
                filter_store.@get (i, 0, out filter);
                filter.enabled = !filter.enabled;
            });

            /* Unselects rows on leaving the object*/
            this.state_flags_changed.connect ((flags) => {
                if ((flags & Gtk.StateFlags.PRELIGHT) == 0) {
                    this.get_selection ().unselect_all ();
                }
            });
        }
        
        private void setup_cell_renderers () {
            col_filter_checkbox.set_cell_data_func (renderer_filter_checkbox, (column, cell, model, iter) => {
                LineFilter filter;
                var cell_toggle = (Gtk.CellRendererToggle) cell;
                model.@get (iter, 0, out filter);
                cell_toggle.set_active (filter.enabled);
            });
            
            col_filter_pattern.set_cell_data_func (renderer_filter_pattern, (column, cell, model, iter) => {
                LineFilter filter;
                var cell_text = (Gtk.CellRendererText) cell;

                model.@get (iter, 0, out filter);
                cell_text.text = filter.pattern != null ? filter.pattern : "";

                if (filter.colors.fg != null) {
                    cell_text.foreground_rgba = filter.colors.fg;
                } else {
                    cell_text.foreground = null;
                }
                if (filter.colors.bg != null) {
                    cell_text.background_rgba = filter.colors.bg;
                } else {
                    cell_text.background = null;
                }
            });

            col_filter_description.set_cell_data_func (renderer_filter_description, (column, cell, model, iter) => {
                LineFilter filter;
                model.@get (iter, 0, out filter);
                var cell_text = (Gtk.CellRendererText) cell;
                cell_text.text = filter.description != null ? filter.description : "";
            });

            col_filter_hits.set_cell_data_func (renderer_filter_hits, (column, cell, model, iter) => {
                LineFilter filter;
                model.@get (iter, 0, out filter);
                var cell_text = (Gtk.CellRendererText) cell;
                cell_text.text = "%u".printf(filter.hits);
            });
        }

        public void add_filter (LineFilter filter) {
            Gtk.TreeIter iter;
            filter_store.append (out iter);
            filter_store.@set (iter, 0, filter);
        }

        public void clear_hit_counters () {
            filter_store.foreach ((filters_model, filter_path, filter_iter) => {
                LineFilter filter;
                filters_model.@get (filter_iter, 0, out filter);
                filter.hits = 0;
                return false;
            });
        }
    }
}
