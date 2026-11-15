/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * counter.vala
 *
 * A simple counter
 * Used for the hit counter
 *
 * José Miguel Fonte
 */

namespace Tags {

    public class Counter : Object {
        public uint count   { get; private set; default = 0; }
        public bool locked  { get; set; default = false; }

        public Counter () {
            reset ();
        }

        public void increment () {
            if (locked) return;
            if (count < uint.MAX) {
                count++;
            }
        }

        public void decrement () {
            if (locked) return;
            if (count > 0) {
                count--;
            }
        }

        public void reset () {
            count = 0;
            locked = false;
        }

        public bool is_zero () {
            return count == 0;
        }
    }

}
