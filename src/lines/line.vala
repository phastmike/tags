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
        private List<MatchingTag> matching_tags;

        public uint         number  { get; construct; }
        public string?      text    { get; construct; }
        public MatchingTag? mtag    { get; private set; default = null; }
        public ulong        hid     = 0;

        public signal void tag_changed ();


        /* CONTRUCTOR */

        public Line (uint number, string? text) {
            Object (number: number, text: text);
            matching_tags = new List<MatchingTag> ();
        }

        ~Line () {
            clear_matching_tags ();
        }

        /* METHODS */

        public Tag? get_tag () {
            return mtag != null ? mtag.tag : null;
        }

        public bool is_tagged () {
            return matching_tags.length () > 0;
        }

        private void update_active_tag () {
            bool found = false;
            for (uint i = 0; i < matching_tags.length (); i++) {
                var mtag = matching_tags.nth_data (i);
                if (mtag.tag.enabled) {
                    if (mtag.tag == this.mtag?.tag) {
                        // Nothing to do, the current tag is already the active tag
                        found = true;
                        break;
                    }
                    this.mtag = mtag;
                    tag_changed ();
                    found = true;
                    break;
                }
            }

            if (!found && _mtag != null) {
                // No enabled matching tags found, clear the active tag
                mtag = null;
                tag_changed ();
            }
        }

        public void add_matching_tag (Tag tag) {
            var matching_tag = new MatchingTag (tag);
            if (matching_tags.find_custom (matching_tag, MatchingTag.matching_tag_compare) == null) {
                matching_tag.handlerid_append (tag.changed.connect (() => {
                    update_active_tag ();
                }));

                matching_tag.handlerid_append (tag.enabled_changed.connect (() => {;
                    update_active_tag ();
                }));

                matching_tag.handlerid_append (tag.to_be_deleted.connect (() => {
                    remove_matching_tag (matching_tag);
                    update_active_tag ();
                }));

                matching_tags.append (matching_tag);
                update_active_tag ();
            }
        }

        public void remove_matching_tag (MatchingTag mtag) {
            if (matching_tags.find_custom (mtag, MatchingTag.matching_tag_compare) != null) {
                mtag.disconnect_all (); 
                matching_tags.remove (mtag);
                update_active_tag ();
            } else {
                warning ("Line %u: tag %s not found in matching tags", this.number, mtag.tag.pattern);
            }
        }

        public void clear_matching_tags () {
            // NOTE: Don't use native foreach here, because we are
            // modifying the list while iterating over it
            matching_tags.foreach ((mtag) => {
                remove_matching_tag (mtag);
            });

            mtag = null;
            tag_changed ();
        }

        public void dump_to_console () {
            message ("Line %u: text: %s", number, text);
            message ("\tActive tag: %s", mtag != null ? mtag.tag.pattern : "null");
            message ("\tMatching tags count: %u", matching_tags.length ());
            foreach (var tag in matching_tags) {
                message ("\t\tTag [%s] enabled: %s", tag.tag.pattern, tag.tag.enabled.to_string ());
            }
        }
    }
}
