/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * model-mixer.vala
 *
 * Mixer/Controller for Lines and Tags models
 *
 * José Miguel Fonte
 */

namespace Tags {
    public class ModelMixer : GLib.Object {
        public TagStore tags;
        public GLib.ListModel lines_model;

        public ModelMixer (GLib.ListModel lines_model, TagStore tags) {
            this.lines_model = lines_model;
            this.tags = tags;

            setup_listeners ();
        }

        private void setup_listeners () {
            tags.model.items_changed.connect ((position, removed, added) => {
                update_mixing ();
                if (added > 0) {
                    for (uint i = position; i < position + added; i++) {
                        var tag = tags.model.get_item (i) as Tag;
                        tag.changed.connect (() => {
                            update_mixing ();
                        });
                    }
                }
            });
        }


        private void update_mixing () {
            // FIXME: optimize this
            for (uint i = 0; i < lines_model.get_n_items (); i++) {
                var line = lines_model.get_item (i) as Line;
                line.tag = null;
                for (uint j = 0; j < tags.ntags; j++) {
                    var tag = tags.model.get_item (j) as Tag;
                    if (tag.applies_to (line.text) && tag.enabled) {
                        line.tag = tag;
                        break;
                    }
                }
            }
        }
    }
}

