/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * filter.vala
 *
 * Actual line visibility filter.
 * Gtk.Filter subclass to filter the ListModel
 */

namespace Tags {
    public class Filter : Gtk.Filter {
        public bool _active = false;

        public bool active {
            get { return _active; }
            set {
                if (_active != value) {
                    _active = value;
                    changed(Gtk.FilterChange.DIFFERENT);
                }
            }
        }

        private Gtk.TreeModel? tags;
        private Gtk.ListStore? tag_store;

        public Filter (Gtk.TreeModel? tags = null) {
            tags = tags;
            tag_store = tags as Gtk.ListStore;
        }

        public override Gtk.FilterMatch get_strictness () {
            return Gtk.FilterMatch.SOME;
        }
 
        public override bool match (Object? item) {
            if (active == false) return true;

            bool ret = false;
            Line line = (Line) item;
            tag_store.foreach ( (model, path, iter) => {
                Tag? tag = null;
                model.@get (iter, 0, out tag);
                if (tag == null) return false;
                if (tag.enabled == true) {
                    if (tag.applies_to (line.text)) {
                        ret = true;
                        return true;
                    }
                }
                return false;
            });
            
            // Apply filter conditions to line, if matches
            // a tag then return true
            return ret;
        }
    }
}
