/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * tags-tree-view.vala
 *
 * Extended Gtk.TreeView as FiltersTreeView
 *
 * José Miguel Fonte
 */

namespace Tagger {
    [GtkTemplate (ui = "/org/ampr/ct1enq/tagger/tags-tree-view.ui")]
    public class TagsTreeView : Gtk.TreeView {
        [GtkChild]
        private unowned Gtk.ListStore tag_store;
        [GtkChild]
        private unowned Gtk.TreeViewColumn col_checkbox;
        [GtkChild]
        private unowned Gtk.TreeViewColumn col_pattern;
        [GtkChild]
        private unowned Gtk.TreeViewColumn col_description;
        [GtkChild]
        private unowned Gtk.TreeViewColumn col_hits;
        [GtkChild]
        private unowned Gtk.CellRendererToggle renderer_checkbox;
        [GtkChild]
        private unowned Gtk.CellRendererText renderer_pattern;
        [GtkChild]
        private unowned Gtk.CellRendererText renderer_description;
        [GtkChild]
        private unowned Gtk.CellRendererText renderer_hits;

        private Gtk.Application application;

        public TagsTreeView (Gtk.Application app) {
            application = app;
            setup_cell_renderers ();
            
            renderer_checkbox.toggled.connect ((path) => {
                Gtk.TreeIter i;
                Tag tag;
                tag_store.get_iter_from_string (out i, path);
                tag_store.@get (i, 0, out tag);
                tag.enabled = !tag.enabled;
            });

            /* Unselects rows on leaving the object*/
            this.state_flags_changed.connect ((flags) => {
                if ((flags & Gtk.StateFlags.PRELIGHT) == 0) {
                    this.get_selection ().unselect_all ();
                }
            });
        }
        
        private void setup_cell_renderers () {
            col_checkbox.set_cell_data_func (renderer_checkbox, (column, cell, model, iter) => {
                Tag tag;
                var cell_toggle = (Gtk.CellRendererToggle) cell;
                model.@get (iter, 0, out tag);
                cell_toggle.set_active (tag.enabled);
            });
            
            col_pattern.set_cell_data_func (renderer_pattern, (column, cell, model, iter) => {
                Tag tag;
                var cell_text = (Gtk.CellRendererText) cell;

                model.@get (iter, 0, out tag);
                cell_text.text = tag.pattern != null ? tag.pattern : "";

                if (tag.colors.fg != null) {
                    cell_text.foreground_rgba = tag.colors.fg;
                } else {
                    cell_text.foreground = null;
                }
                if (tag.colors.bg != null) {
                    cell_text.background_rgba = tag.colors.bg;
                } else {
                    cell_text.background = null;
                }
            });

            col_description.set_cell_data_func (renderer_description, (column, cell, model, iter) => {
                Tag tag;
                model.@get (iter, 0, out tag);
                var cell_text = (Gtk.CellRendererText) cell;
                cell_text.text = tag.description != null ? tag.description : "";
            });

            col_hits.set_cell_data_func (renderer_hits, (column, cell, model, iter) => {
                Tag tag;
                model.@get (iter, 0, out tag);
                var cell_text = (Gtk.CellRendererText) cell;
                cell_text.text = "%u".printf(tag.hits);
            });
        }

        public void add_tag (Tag tag) {
            Gtk.TreeIter iter;
            tag_store.append (out iter);
            tag_store.@set (iter, 0, tag);
        }

        public void remove_tag (Tag tag) {
            tag_store.foreach ((model, path, iter) => {
                Tag t;
                model.@get (iter, 0, out t);

                if (t == tag) {
                    tag_store.remove (ref iter);
                    return true;
                } else {
                    return false;
                }
            });
        }

        public void clear_hit_counters () {
            tag_store.foreach ((tags_model, tag_path, tag_iter) => {
                Tag tag;
                tags_model.@get (tag_iter, 0, out tag);
                tag.hits = 0;
                return false;
            });
        }
        
        public void clear_tags () {
            tag_store.clear ();
        }

        public void to_file (File file) {
            Json.Node root = new Json.Node (Json.NodeType.ARRAY);
            Json.Array array = new Json.Array ();

            tag_store.foreach ((model, path, iter) => {
                Tag tag;
                model.get (iter, 0, out tag);
                Json.Node node = Json.gobject_serialize (tag);
                array.add_element (node); 
                return false;
            });

            root.take_array (array);
            Json.Generator generator = new Json.Generator ();
            generator.pretty = true;
            generator.set_root (root);
            try {
                generator.to_file (file.get_path ());
            } catch (Error e) {
                error ("Json.Generator::to_file error: %s", e.message);
            }
        }
    }
}
