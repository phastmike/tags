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
        public bool enabled;
        public string pattern;
        public string description;
        public uint hits; // Should be here?
        public ColorScheme colors;
        
        public LineFilter (string pattern, string description, ColorScheme colors) {
            this.pattern = pattern;
            this.description = description;
            this.colors = colors;

            hits = 0;
            enabled = true;
        }
    }
}
