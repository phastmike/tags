/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * line-store.vala
 *
 * Class wrapper for GLib.ListStore.
 * Contains multiple lines representing the document.
 * 
 * Uses a GLib.ListStore instead of a Gtk.StringList
 * to be more generic if needed.
 *
 * NOTE:
 * Keeping a reference of the first applicable tag
 * might be interesting or not. Evaluate
 *
 * José Miguel Fonte
 */

namespace Tags {

    public class Line : Object {
        public uint number {get; set; default = 0;}
        public string? text {get; private set; default = null;}
        public Tag? tag {get; set; default = null;}

        public Line (int number, string? text, Tag? tag = null) {
            this.number = number;
            this.text = text;
            this.tag = tag;
        }
    }

    public class LineStore : Object {
        public GLib.ListStore store;

        public LineStore () {
            store = new GLib.ListStore (typeof(Line));
            /*
            store.append (new Line (1, "Linha 1"));
            store.append (new Line (20, "Linha 2"));
            store.append (new Line (3000, "Linha 3"));
            */
        }
    }

}
