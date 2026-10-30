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
        private List<Tag> matching_tags;

        private ulong handlerid_tag_changed = 0;
        private ulong handlerid_tag_enabled_changed = 0;

        public uint     number  { get; construct; }     // Is this high enough :) ?
        public string?  text    { get; construct; }
        public ulong    hid     = 0;

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

        public signal void tag_changed ();

        /* CONTRUCTOR */
        construct {
            tag = null;
        }

        public Line (uint number, string? text) {
            Object (number: number, text: text);
            matching_tags = new List<Tag> ();
        }

        /* METHODS */

        public Tag? get_active_tag () {
            foreach (var tag in matching_tags) {
                message ("Line %u Tag [%s] enabled: %s", number, tag.pattern, tag.enabled.to_string ());
                if (tag.enabled) {
                    return tag;
                }
            }
            return null;
        }

        public void add_matching_tag (Tag tag) requires (tag != null) {
            message ("Add matching_tag (%s) to line %u", tag.pattern, number);
            if (matching_tags.find (tag) == null) {

                matching_tags.append (tag);

                handlerid_tag_changed = tag.changed.connect (() => {
                    message ("Line %u: tag match criteria changed : %s", this.number, tag.pattern);
                    this.tag = get_active_tag ();
                    tag_changed ();
                });

                handlerid_tag_enabled_changed = tag.enabled_changed.connect (() => {
                    message ("Line %u: tag enabled changed : %s", this.number, tag.pattern);
                    this.tag = get_active_tag ();
                    tag_changed ();
                });
            }
        }

        public void remove_matching_tag (Tag tag) requires (tag != null) {
            if (matching_tags.find (tag) != null) {

                if (handlerid_tag_changed != 0) tag.disconnect (handlerid_tag_changed);
                if (handlerid_tag_enabled_changed != 0) tag.disconnect (handlerid_tag_enabled_changed);

                matching_tags.remove (tag);

                this.tag = get_active_tag ();

                tag_changed ();

                message ("Line %u: tag %s removed from matching tags", this.number, tag.pattern);
                return;
            } else {
                warning ("Line %u: tag %s not found in matching tags", this.number, tag.pattern);
                return;
            }
        }

        public void clear_matching_tags () {
            foreach (var tag in matching_tags) {
                remove_matching_tag (tag);
            } 
        }
    }
}
