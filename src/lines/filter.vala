/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * filter.vala
 *
 * Actual line visibility filter.
 * Gtk.Filter subclass to filter the ListModel
 * 
 * NOTE:
 * Depends on tags model which will be changed
 */

namespace Tags {
    public class Filter : Gtk.Filter {
        private bool _active = false;
        private unowned GLib.ListModel tags;

        public bool active {
            get { return _active; }
            set {
                if (_active != value) {
                    _active = value;
                    changed (Gtk.FilterChange.DIFFERENT);
                }
            }
        }

        public Filter (GLib.ListModel tags) {
            this.tags = tags;
            this.tags.items_changed.connect ( (pos, add, removed) => {
                changed (Gtk.FilterChange.DIFFERENT);

                /*
                var ctx = tags.get_item (pos) as TagContext;
                var tag = ctx.tag;
                if (tag != null) {
                    tag.enable_changed.connect ( (v) => {
                        changed (Gtk.FilterChange.DIFFERENT);
                    });
                }
                */
            });
        }

        public override Gtk.FilterMatch get_strictness () {
            return Gtk.FilterMatch.SOME;
        }
 
        public override bool match (Object? item) {
            if (active == false) { return true; }
            if (item == null) { return false; }

            Line line = (Line) item;
            for (uint i = 0; i < tags.get_n_items (); i++) {
                var ctx = tags.get_item (i) as TagContext;
                if (ctx.tag.enabled == true && ctx.tag.applies_to (line.text)) {
                    return true;
                }
            }

            return false;
        }

        public void update () {
            changed (Gtk.FilterChange.DIFFERENT);
        }
    }
}
