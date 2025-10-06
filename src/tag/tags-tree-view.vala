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
    [GtkTemplate (ui = "/io/github/phastmike/tags/ui/tags-tree-view.ui")]
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

        public uint ntags {
            public get {
                return ((Gtk.TreeModel) tag_store).iter_n_children (null);
            }
        }

        public signal void no_active_tags ();

        public TagsTreeView () {
            setup_cell_renderers ();
            
            renderer_checkbox.toggled.connect ((path) => {
                Gtk.TreeIter iter;
                tag_store.get_iter_from_string (out iter, path);
                Tag? tag = get_tag_from_model_with_iter (tag_store, iter);
                if (tag != null) {
                    tag.enabled = !tag.enabled;

                    if (get_n_tags_enabled () == 0) {
                        no_active_tags ();
                    }
                }
            });

            tag_store.row_deleted.connect ((path, iter) => {
                if (ntags == 0 ) no_active_tags ();
            });
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

        private Tag? get_tag_from_model_with_iter (Gtk.TreeModel model, Gtk.TreeIter iter) {
            Tag? tag = null;
            model.@get (iter, 0, out tag);
            return tag;
        }
        
        private void setup_cell_renderers () {
            col_checkbox.set_cell_data_func (renderer_checkbox, (column, cell, model, iter) => {
                var cell_toggle = (Gtk.CellRendererToggle) cell;
                Tag? tag = get_tag_from_model_with_iter (model, iter);
                if (tag != null) cell_toggle.set_active (tag.enabled);
            });
            
            col_pattern.set_cell_data_func (renderer_pattern, (column, cell, model, iter) => {
                var cell_text = (Gtk.CellRendererText) cell;
                Tag? tag = get_tag_from_model_with_iter (model, iter);

                if (tag == null) return;

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
                Tag? tag = get_tag_from_model_with_iter (model, iter);
                var cell_text = (Gtk.CellRendererText) cell;
                cell_text.text = tag.description ?? "";
            });

            col_hits.set_cell_data_func (renderer_hits, (column, cell, model, iter) => {
                Tag? tag = get_tag_from_model_with_iter (model, iter);
                if (tag == null) return;
                var cell_text = (Gtk.CellRendererText) cell;
                cell_text.text = "%u".printf(tag.hits);
            });

            col_regex.set_cell_data_func (renderer_regex, (column, cell, model, iter) => {
                Tag? tag = get_tag_from_model_with_iter (model, iter);
                if (tag == null) return;
                var cell_pixbuf = (Gtk.CellRendererPixbuf) cell;
                cell_pixbuf.icon_name = tag.is_regex ? "process-stop-symbolic" : null;
            });

            col_case.set_cell_data_func (renderer_case, (column, cell, model, iter) => {
                Tag? tag = get_tag_from_model_with_iter (model, iter);
                if (tag == null) return;
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
                Tag? tag = get_tag_from_model_with_iter (model, iter);

                if (tag == null) return false;

                if (tag == to_remove) {
                    tag_store.remove (ref iter);
                    return true;
                } else {
                    return false;
                }
            });
        }

        // We could have a quicker method to check if there's at least one
        // tag enabled and exit right after, instead of iterating over all members.
        // but we wouldn't get the number though. Is it worth it?
        public uint get_n_tags_enabled () {
            uint active_tags = 0;

            tag_store.foreach ( (model, path, iter) => {
                var tag = get_tag_from_model_with_iter (model, iter);
                if (tag == null) return false;
                if (tag.enabled == true  && tag.hits > 0) {
                    active_tags += 1; 
                }
                return false;
            });

            return active_tags;
        }

        public void toggle_tag (int nr) requires (nr >= 0 && nr <= 9) {
            Gtk.TreeIter iter;
            if (model.@get_iter_from_string (out iter, nr.to_string ())) {
                Tag? tag = get_tag_from_model_with_iter (model, iter);
                if (tag == null) return;
                tag.enabled = !tag.enabled;
            }

            queue_draw ();

            if (get_n_tags_enabled () == 0) {
                no_active_tags ();
            }
        }

        public void tags_set_enable (bool enable) {
            model.foreach ((model, path, iter) => {
                Tag? tag = get_tag_from_model_with_iter (model, iter);
                if (tag == null) return false;
                tag.enabled = enable;
                return false;
            });
            queue_draw ();
        }

        public void reset_hit_counters () {
            tag_store.foreach ((tags_model, tag_path, tag_iter) => {
                Tag? tag = get_tag_from_model_with_iter (tags_model, tag_iter);
                if (tag == null) return false;
                tag.hits = 0;
                return false;
            });
        }
        
        public void clear_tags () {
            tag_store.clear ();
            no_active_tags (); // OK?
        }

        public ColorScheme? get_color_scheme_for_text (string text) {
            ColorScheme? ret = null;
            if (ntags == 0) return null;
            tag_store.foreach ( (model, path, iter) => {
                Tag? tag = null;
                model.@get (iter, 0, out tag);
                if (tag == null) return true;
                if (tag.enabled == true) {
                    if (tag.applies_to (text)) {
                        ret = tag.colors;
                        return true;
                    }
                }
                return false;
            });

            return ret;
        }

        public Gdk.RGBA? get_bg_color_for_text (string text) {
            Gdk.RGBA? ret = null;
            tag_store.foreach ( (model, path, iter) => {
                var tag = get_tag_from_model_with_iter (model, iter);
                if (tag == null) return false;
                if (tag.enabled == true) {
                    if (tag.applies_to (text)) {
                        ret = tag.colors.bg;
                        return true;
                    }
                }
                return false;
            });

            return ret;
        }

        public Gdk.RGBA? get_fg_color_for_text (string text) {
            Gdk.RGBA? ret = null;
            tag_store.foreach ( (model, path, iter) => {
                var tag = get_tag_from_model_with_iter (model, iter);
                if (tag == null) return false;
                if (tag.enabled == true) {
                    if (tag.applies_to (text)) {
                        ret = tag.colors.fg;
                        return true;
                    }
                }
                return false;
            });
            return ret;
        }
    }
}
