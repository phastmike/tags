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
        private Tag? _tag = null;

        public uint     number  { get; construct; }
        public string?  text    { get; construct; }

        public Tag? tag {
            get  {
                return _tag;
            }
            set {
                if (_tag != value) {
                    _tag = value;
                    tag_changed ();
                }
            }
        } 

        public List<Tag> matching_tags;
        public ulong sighandler = 0;    // NOTE: Placeholder for signal handler ID. Keep/Remove?

        public signal void tag_changed ();

        public Line (uint number, string? text, Tag? tag = null) {
            Object (number: number, text: text);
            matching_tags = new List<Tag> ();
            this.tag = tag;
        }

        public Tag? get_active_tag () {
            foreach (var tag in matching_tags) {
                if (tag.enabled) {
                    return tag;
                }
            }
            return null;
        }
    }
}
