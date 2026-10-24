/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * lines-view-controller.vala
 *
 * Mixer/Controller for Lines and Tags models
 *
 * José Miguel Fonte
 */

namespace Tags {
    public class LinesViewController : GLib.Object {
        public TagStore tags;
        public Filterer? filterer;
        public GLib.ListModel lines_model;

        private bool updating = false;
        private bool queued_update = false;

        public signal void mix_updated ();
        public signal void mixing_progress_update (double progress);

        public LinesViewController (GLib.ListModel lines_model, TagStore tags, Filterer? filterer = null) {
            this.lines_model = lines_model;
            this.tags = tags;
            this.filterer = filterer;

            //setup_listeners ();
        }

        // FIXME: NOT NEEDED -> REMOVE AFTER REFACTORING IF NOT USED
        /*
        private void setup_listeners () {
            return;
            tags.model.items_changed.connect ((position, removed, added) => {
                update_mixing ();
                if (added > 0) {
                    for (uint i = position; i < position + added; i++) {
                        var ctx = tags.model.get_item (i) as TagContext;
                        var tag = ctx.tag;
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
        */

        public void update_mixing () {
            message ("LinesViewController.update_mixing ()");
            Idle.add (() => {
                if (updating) {
                    queued_update = true;
                    return false;
                }

                update_mixing_async.begin ( (s, p) => {
                    update_mixing_async.end (p);
                    mix_updated ();
                });
                return false;
            });
        }

        async void update_mixing_async ()  {
            updating = true;
            tags.hitcounter_reset_all ();
            SourceFunc callback = update_mixing_async.callback;
            for (uint i = 0; i < lines_model.get_n_items (); i++) {
                var line = lines_model.get_item (i) as Line;
                Idle.add_once (() => {
                    update_mixing_for_line (line);
                    Idle.add ((owned) callback);
                });
                callback = update_mixing_async.callback;
                yield;
                double progress = (double)(i + 1) / (double)lines_model.get_n_items ();
                mixing_progress_update (progress);
            }
            updating = false;
            if (queued_update) {
                queued_update = false;
                update_mixing_async.begin ( (s, p) => {
                    update_mixing_async.end (p);
                    message ("LinesViewController.update_mixing () - mix_upated");
                    mix_updated ();
                });
            }
        }

        public void update_mixing_for_line (Line line) {
            line.tag = null;
            line.matching_tags = null;
            for (uint j = 0; j < tags.n_items; j++) {
                var ctx = tags.model.get_item (j) as TagContext;
                var tag = ctx.tag;
                // FIXME: Tag should be applied even with enabled = false
                if (tag.applies_to (line.text)) {
                    ctx.hit_counter.increment ();
                    line.matching_tags.append (tag);
                    /*
                    if (line.tag == null) {
                        line.tag = tag;
                    }
                    */
                    //break;
                }
            }
        }

        public void count_hits_for_tag (Tag tag) {
        return; ////////////////////////////////////////////////////////////////////////////////////
            var ctx = tags.get_context_for_tag (tag);
            ctx.hit_counter.reset ();
            for (uint i = 0; i < lines_model.get_n_items (); i++) {
                var line = lines_model.get_item (i) as Line;
                if (tag.applies_to (line.text)) {
                    ctx.hit_counter.increment ();
                }
            }
        }

        public void count_tag_hits () {
        return; ////////////////////////////////////////////////////////////////////////////////////
            tags.hitcounter_reset_all ();
            for (uint i = 0; i < lines_model.get_n_items (); i++) {
                var line = lines_model.get_item (i) as Line;
                for (uint j = 0; j < tags.n_items; j++) {
                    var ctx = tags.model.get_object (j) as TagContext;
                    var tag = ctx.tag;
                    if (tag.applies_to (line.text)) {
                        ctx.hit_counter.increment ();
                    }
                }
            }
        }

    }
}

