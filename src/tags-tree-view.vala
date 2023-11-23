/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * tags-tree-view.vala
 *
 * Extended Gtk.TreeView as FiltersTreeView
 *
 * José Miguel Fonte
 */

namespace Tags {
    [GtkTemplate (ui = "/io/github/phastmike/tags/tags-tree-view.ui")]
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
        private unowned Gtk.TreeViewColumn col_regex;
        [GtkChild]
        private unowned Gtk.TreeViewColumn col_case;
        [GtkChild]
        private unowned Gtk.CellRendererToggle renderer_checkbox;
        [GtkChild]
        private unowned Gtk.CellRendererText renderer_pattern;
        [GtkChild]
        private unowned Gtk.CellRendererText renderer_description;
        [GtkChild]
        private unowned Gtk.CellRendererText renderer_hits;
        [GtkChild]
        private unowned Gtk.CellRendererPixbuf renderer_regex;
        [GtkChild]
        private unowned Gtk.CellRendererPixbuf renderer_case;

        public uint ntags;
        private Gtk.Application application;

        public TagsTreeView (Gtk.Application app) {
            application = app;
            setup_cell_renderers ();
            
            ntags = 0;

            renderer_checkbox.toggled.connect ((path) => {
                Gtk.TreeIter iter;
                tag_store.get_iter_from_string (out iter, path);
                Tag tag = get_tag_from_model_with_iter (tag_store, iter);
                tag.enabled = !tag.enabled;
            });

            tag_store.row_inserted.connect ((path, iter) => {
                ntags++;
            });

            tag_store.row_deleted.connect ((path, iter) => {
                ntags--;
            });

            /* Unselects rows on leaving the object */
            /*
            this.state_flags_changed.connect ((flags) => {
                if ((flags & Gtk.StateFlags.PRELIGHT) == 0) {
                    this.get_selection ().unselect_all ();
                }
            });
            */
        }

        public Tag? get_selected_tag () {
            Tag tag;
            Gtk.TreeIter iter;
            Gtk.TreeModel model;

            var selection = this.get_selection ();

            if (selection.get_selected (out model, out iter) == true) {
                return get_tag_from_model_with_iter (model, iter);
            } else {
                return null;
            }
        }

        private Tag get_tag_from_model_with_iter (Gtk.TreeModel model, Gtk.TreeIter iter) {
            Tag tag;
            model.@get (iter, 0, out tag);
            return tag;
        }
        
        private void setup_cell_renderers () {
            col_checkbox.set_cell_data_func (renderer_checkbox, (column, cell, model, iter) => {
                var cell_toggle = (Gtk.CellRendererToggle) cell;
                cell_toggle.set_active (get_tag_from_model_with_iter (model, iter).enabled);
            });
            
            col_pattern.set_cell_data_func (renderer_pattern, (column, cell, model, iter) => {
                var cell_text = (Gtk.CellRendererText) cell;
                Tag tag = get_tag_from_model_with_iter (model, iter);

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
                Tag tag = get_tag_from_model_with_iter (model, iter);
                var cell_text = (Gtk.CellRendererText) cell;
                cell_text.text = tag.description != null ? tag.description : "";
            });

            col_hits.set_cell_data_func (renderer_hits, (column, cell, model, iter) => {
                Tag tag = get_tag_from_model_with_iter (model, iter);
                var cell_text = (Gtk.CellRendererText) cell;
                cell_text.text = "%u".printf(tag.hits);
            });

            col_regex.set_cell_data_func (renderer_regex, (column, cell, model, iter) => {
                Tag tag = get_tag_from_model_with_iter (model, iter);
                var cell_pixbuf = (Gtk.CellRendererPixbuf) cell;
                cell_pixbuf.icon_name = tag.is_regex ? "process-stop-symbolic" : null;
            });

            col_case.set_cell_data_func (renderer_case, (column, cell, model, iter) => {
                Tag tag = get_tag_from_model_with_iter (model, iter);
                var cell_pixbuf = (Gtk.CellRendererPixbuf) cell;
                cell_pixbuf.icon_name = tag.is_case_sensitive ? "process-stop-symbolic" : null;
            });
        }

        public void add_tag (Tag tag, bool prepend = false) {
            Gtk.TreeIter iter;
            if (prepend) {
                tag_store.prepend (out iter);
            } else {
                tag_store.append (out iter);
            }
            tag_store.@set (iter, 0, tag);
        }

        public void remove_tag (Tag to_remove) {
            tag_store.foreach ((model, path, iter) => {
                Tag tag = get_tag_from_model_with_iter (model, iter);

                if (tag == to_remove) {
                    tag_store.remove (ref iter);
                    return true;
                } else {
                    return false;
                }
            });
        }

        public void toggle_tag (int nr) requires (nr >= 0 && nr <= 9) {
            Gtk.TreeIter iter;
            if (model.@get_iter_from_string (out iter, nr.to_string ())) {
                Tag tag = get_tag_from_model_with_iter (model, iter);
                tag.enabled = !tag.enabled;
            }
            queue_draw ();
        }

        public void tags_set_enable (bool enable) {
            model.foreach ((model, path, iter) => {
                Tag tag = get_tag_from_model_with_iter (model, iter);
                tag.enabled = enable;
                return false;
            });
            queue_draw ();
        }

        public void clear_hit_counters () {
            tag_store.foreach ((tags_model, tag_path, tag_iter) => {
                Tag tag = get_tag_from_model_with_iter (tags_model, tag_iter);
                tag.hits = 0;
                return false;
            });
        }
        
        public void clear_tags () {
            tag_store.clear ();
            ntags = 0;
        }

        public void to_file (File file) {
            Json.Node root = new Json.Node (Json.NodeType.ARRAY);
            Json.Array array = new Json.Array ();

            tag_store.foreach ((model, path, iter) => {
                Tag tag = get_tag_from_model_with_iter (model, iter);
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
