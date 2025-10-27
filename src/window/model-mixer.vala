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
        private TagStore tags;
        private Lines lines;

        public ModelMixer (Lines lines, TagStore tags) {
            this.lines = lines;
            this.tags = tags;

            setup_listeners ();
        }

        private void setup_listeners () {
            message ("Setting up listeners");
            tags.model.items_changed.connect_after ((position, removed, added) => {
                message ("Cenas");
                for (uint i = 0; i < lines.model.get_n_items (); i++) {
                    var line = lines.model.get_item (i) as Line;
                    for (uint j = 0; j < tags.model.get_n_items (); j++) {
                        var tag = tags.model.get_item (j) as Tag;
                        if (tag.applies_to (line.text) && tag.enabled) {
                            line.tag = tag;
                            break;
                        }
                    }
                }
            });
        }
    }
}

