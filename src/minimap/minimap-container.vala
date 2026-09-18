/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * minimap-container.vala
 *
 * Minimap container
 *
 * José Miguel Fonte
 */

namespace Tags {
    public class MinimapContainer : Adw.Bin {
        private Gtk.Revealer revealer;
        public bool reveal {
            get {
                return revealer.get_reveal_child ();
            }
            set {
                revealer.set_reveal_child (value);
            }
        }

        public MinimapContainer (Minimap minimap) {
            revealer = new Gtk.Revealer ();
            revealer.set_child (minimap);
            revealer.set_transition_duration (200);
            revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_LEFT);

            set_child (revealer);
        }
    }
}
