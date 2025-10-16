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
    [GtkTemplate (ui = "/io/github/phastmike/tags/ui/tags-column-view.ui")]
    public class TagsColumnView : Gtk.Box {
        [GtkChild]
        public Gtk.ScrolledWindow scrolled;
        [GtkChild]
        public Gtk.ColumnView column_view;

        //public TagStore tag_store;
        public GLib.ListModel model;
        private Gtk.Application application;

        public TagsColumnView (GLib.ListModel model) {
            this.model = model; 
            Gtk.SingleSelection selection_model = new Gtk.SingleSelection (model);
            column_view.set_model (selection_model);
            selection_model.set_autoselect (false);
            selection_model.set_can_unselect (true);

            // Does not work
            column_view.activate.connect ( (pos) => {
                message ("Row %u activated...", pos);
            });
        }

        [GtkCallback]
        private void tags_enabled_setup_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            Gtk.CheckButton cb_enabled = new Gtk.CheckButton ();
            cb_enabled.add_css_class ("selection-mode");
            listitem.child = cb_enabled;
        }

        [GtkCallback]
        private void tags_enabled_bind_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            Gtk.CheckButton cb_enabled = listitem.child as Gtk.CheckButton;
            Tag tag = listitem.item as Tag;
            cb_enabled.set_active (tag.enabled);
        }

        [GtkCallback]
        private void tags_pattern_setup_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            Gtk.Label label_pattern = new Gtk.Label ("");
            label_pattern.set_ellipsize(Pango.EllipsizeMode.END);
            listitem.child = label_pattern;
            label_pattern.xalign = 0;
        }

        [GtkCallback]
        private void tags_pattern_bind_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            Gtk.Label label_pattern = listitem.child as Gtk.Label;
            Tag tag = listitem.item as Tag;
            label_pattern.set_text (tag.pattern);
        }

        [GtkCallback]
        private void tags_regex_setup_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            Gtk.Label label_regex = new Gtk.Label ("");
            listitem.child = label_regex;
        }

        [GtkCallback]
        private void tags_regex_bind_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            Gtk.Label label_regex = listitem.child as Gtk.Label;
            Tag tag = listitem.item as Tag;
            label_regex.set_text (tag.is_regex ? "x" : " ");
        }

        [GtkCallback]
        private void tags_case_setup_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            Gtk.Label label_case = new Gtk.Label ("");
            listitem.child = label_case;
        }

        [GtkCallback]
        private void tags_case_bind_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            Gtk.Label label_case = listitem.child as Gtk.Label;
            Tag tag = listitem.item as Tag;
            label_case.set_text (tag.is_case_sensitive ? "x" : " ");
        }

        [GtkCallback]
        private void tags_description_setup_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            Gtk.Label label = new Gtk.Label ("");
            label.set_ellipsize(Pango.EllipsizeMode.END);
            listitem.child = label;
            label.xalign = 0;
        }

        [GtkCallback]
        private void tags_description_bind_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            Gtk.Label label = listitem.child as Gtk.Label;
            Tag tag = listitem.item as Tag;
            label.set_text (tag.description);
        }

        [GtkCallback]
        private void tags_hits_setup_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            Gtk.Label label = new Gtk.Label ("");
            listitem.child = label;
        }

        [GtkCallback]
        private void tags_hits_bind_handler (Gtk.SignalListItemFactory factory, GLib.Object listitemm) {
            Gtk.ListItem listitem = (Gtk.ListItem) listitemm;
            Gtk.Label label = listitem.child as Gtk.Label;
            Tag tag = listitem.item as Tag;
            label.set_text ("%u".printf (tag.hits));
        }
    }
}
