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
    [GtkTemplate (ui = "/io/github/phastmike/tags/tag/tags-view.ui")]
    public class TagsView : Gtk.Box {
        [GtkChild]
        public Gtk.ScrolledWindow scrolled;
        [GtkChild]
        public Gtk.ListBox listbox;

        public GLib.ListModel model;
        private Gtk.Application application;

        public TagsView (GLib.ListModel model) {
            this.model = model; 

            listbox.bind_model (this.model, (obj) => {
                var tag = obj as Tag;
                var row = new TagRow (tag);

                return row as Gtk.Widget;
            });
        }
    }
}
