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

        // Should be decoupled
        private Tag? _tag = null;
        public Tag? tag {
            get  {
                return _tag;
            }
            set {
                //if (true) {
                if (_tag != value) {
                    _tag = value;
                    if (value != null) {
                        this.actual_style = "tag-%s".printf (tag.colors.name);
                    } else {
                        this.actual_style = null;
                    }
                    tag_changed ();
                }
            }
        } 

        public string? actual_style = null;
        public ulong sighandler = 0;


        public signal void tag_changed ();

        public Line (uint number, string? text, Tag? tag = null) {
            this.number = number;
            this.text = text;
            this.tag = tag;
            actual_style = null;
        }
    }
}
