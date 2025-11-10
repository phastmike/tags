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
        public Filterer? filterer;
        public GLib.ListModel lines_model;

        private bool updating = false;
        private bool queued_update = false;

        public signal void mixing_progress_update (double progress);

        public ModelMixer (GLib.ListModel lines_model, TagStore tags, Filterer? filterer = null) {
            this.lines_model = lines_model;
            this.tags = tags;
            this.filterer = filterer;

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
                            if (filterer != null) {
                                if (filterer.filter.active)
                                    filterer.filter.update ();
                            }
                        });
                    }
                }
            });
        }

        public void update_mixing () {
            Idle.add (() => {
                if (updating) {
                    queued_update = true;
                    return false;
                }
                update_mixing_async.begin ();
                /*
                update_mixing_async.begin ( (s, p) => {
                    update_mixing_async.end (p);
                });
                */
                return false;
            });
        }

        async void update_mixing_async ()  {
            updating = true;
            SourceFunc callback = update_mixing_async.callback;
            for (uint i = 0; i < lines_model.get_n_items (); i++) {
                var line = lines_model.get_item (i) as Line;
                Idle.add_once (() => {
                    update_mixing_for_line (line);
                    Idle.add ((owned) callback);
                    //return false;
                });
                callback = update_mixing_async.callback;
                yield;
                double progress = (double)(i + 1) / (double)lines_model.get_n_items ();
                mixing_progress_update (progress);
            }
            updating = false;
            if (queued_update) {
                queued_update = false;
                update_mixing_async.begin ();
            }
        }

        public void update_mixing_for_line (Line line) {
            line.tag = null;
            for (uint j = 0; j < tags.ntags; j++) {
                var tag = tags.model.get_item (j) as Tag;
                if (tag.applies_to (line.text) && tag.enabled) {
                    line.tag = tag;
                    break;
                }
            }
        }

        public void update_mixing_sync () {
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

