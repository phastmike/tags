/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * line.vala
 *
 * Class representing a line number and the line text
 * Contains one line specific line
 */

namespace Tags {
    public class Line : Object {
        public uint number {get;  private set; default = 0;}
        public string? text {get; private set; default = null;}
        public Tag? tag {get; set; default = null;} // Should be decoupled
        public string? actual_style = null;
        public ulong sighandler = 0;

        public Line (uint number, string? text, Tag? tag = null) {
            this.number = number;
            this.text = text;
            this.tag = tag;
            actual_style = null;
        }
    }
}
