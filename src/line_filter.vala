/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * FILENAME.vala
 *
 * DESCRIPTION
 * 
 *
 * José Miguel Fonte
 */

namespace Gtat {

    public class LineFilter : Object {
        bool enabled;
        string pattern;
        string description;
        uint hits; // Should be here?
        
        Gdk.RGBA? fg_color;
        Gdk.RGBA? bg_color;

        public LineFilter (string pattern, string description, Gdk.RGBA? fg_color = null, Gdk.RGBA? bg_color = null) {
            this.pattern = pattern;
            this.description = description;
            this.fg_color = fg_color;
            this.bg_color = bg_color;

            hits = 0;
            enabled = true;
        }
    }
}
