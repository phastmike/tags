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
    [GtkTemplate (ui = "/io/github/phastmike/tags/ui/tags-view.ui")]
    public class TagsView : Gtk.Box {
        [GtkChild]
        public Gtk.ScrolledWindow scrolled;
        [GtkChild]
        public Gtk.ListBox listbox;

        public GLib.ListModel model;
        private Gtk.Application application;

        private Gtk.DropTarget drop_target;

        public TagsView (GLib.ListModel model) {
            this.model = model; 

            drop_target = new Gtk.DropTarget(typeof (TagRow), Gdk.DragAction.MOVE);
            listbox.add_controller (drop_target);
    // Drop Handling
    drop_target.drop.connect((drop, value, x, y) => {
        var value_row = value.get_object() as TagRow?;
        Gtk.ListBoxRow? target_row = listbox.get_row_at_y((int) y);
        // If value or the target row is null, do not accept the drop
        if (value_row == null || target_row == null) {
            return false;
        }

        int target_index = target_row.get_index();

        message("HERE from %d to %d", value_row.get_index (), target_index);

        // do it at model !
        (model as GLib.ListStore).remove (value_row.get_index ());
        (model as GLib.ListStore).insert (target_index, value_row.tag);
        target_row.set_state_flags(Gtk.StateFlags.NORMAL, true);

        return true;
    });
            


            listbox.bind_model (this.model, (obj) => {
                var tag = obj as Tag;
                var row = new TagRow (tag);

            var drop_controller = new Gtk.DropControllerMotion ();
            var drag_source = new Gtk.DragSource () {
                actions = Gdk.DragAction.MOVE
            };

            row.add_controller (drag_source);
            row.add_controller (drop_controller);
        // Drag handling
        drag_source.prepare.connect ( (x, y) => {
            row.drag_x = x;
            row.drag_y = y;

            Value value = Value(typeof (TagRow));
            value.set_object(row);

            return new Gdk.ContentProvider.for_value(value);
        });

        drag_source.drag_begin.connect((drag) => {
            var drag_widget = new Gtk.ListBox();

            drag_widget.set_size_request(row.get_width(), row.get_height());
            drag_widget.add_css_class("boxed-list");

            var drag_row = new TagRow(row.tag);
            drag_row.add_css_class ("dimmed");

            drag_widget.append(drag_row);
            drag_widget.drag_highlight_row(drag_row);

            var icon = Gtk.DragIcon.get_for_drag(drag) as Gtk.DragIcon;
            icon.child = drag_widget;

            drag.set_hotspot((int) row.drag_x, (int) row.drag_y);
        });

        // Update row visuals during DnD operation
        drop_controller.enter.connect (() => listbox.drag_highlight_row (row));
        drop_controller.leave.connect (() => listbox.drag_unhighlight_row ());

        //}

                return row as Gtk.Widget;
            });
        }
    }
}
