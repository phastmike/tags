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
        public bool _active = false;

        public bool active {
            get { return _active; }
            set {
                if (_active != value) {
                    _active = value;
                    changed (Gtk.FilterChange.DIFFERENT);
                }
            }
        }

        private GLib.ListModel tags;

        public Filter (GLib.ListModel tags) {
            this.tags = tags;
            //FIXME NOTE TODO It's a Hackm it could be better
            this.tags.items_changed.connect ( (pos, add, removed) => {
                var tag = tags.get_item (pos) as Tag; 
                if (tag != null) {
                    tag.enable_changed.connect ( (v) => {
                        changed (Gtk.FilterChange.DIFFERENT);
                    });
                }
            });
        }

        public override Gtk.FilterMatch get_strictness () {
            return Gtk.FilterMatch.SOME;
        }
 
        public override bool match (Object? item) {
            if (active == false) return true;
            Line line = (Line) item;
            for (uint i = 0; i < tags.get_n_items (); i++) {
                var tag = tags.get_item (i) as Tag;
                if (tag.enabled == true && tag.applies_to (line.text)) {
                    return true;
                }
            }
            
            return false;
            // Apply filter conditions to line, if matches
            // a tag then return true
        }

        public void update () {
            changed (Gtk.FilterChange.DIFFERENT);
        }
    }
}
