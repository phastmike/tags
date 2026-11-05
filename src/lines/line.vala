/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * line.vala
 *
 * Class representing a line number and the line text
 * Contains one line specific line
 */

namespace Tags {
    public class MatchingTag : Object {
        public Tag tag {get; construct;}
        private List<ulong> handlerids;

        public static int matching_tag_compare (MatchingTag a, MatchingTag b) {
            MatchingTag mta = (MatchingTag) a;
            MatchingTag mtb = (MatchingTag) b;
            message ("MatchingTag: matching_tag_compare: a.tag: %s, b.tag: %s", mta.tag.pattern, mtb.tag.pattern);
            if (mta.tag == mtb.tag)
                return 0;
            else
                return -1;
        }

        construct {
            handlerids = new List<ulong> ();
        }

        public MatchingTag (Tag tag) {
            Object (tag: tag);
        }

        public void handlerid_append (ulong handlerid) {
            if (handlerid != 0) {
                handlerids.append (handlerid);
            } else {
                warning ("MatchingTag: Tag: %s handlerid_append: handlerid is 0", tag.pattern);
            }
        }

        public void handlerid_remove (ulong handlerid) {
            if (handlerid != 0) {
                if (handlerids.find (handlerid) != null && handlerid != 0) {
                    tag.disconnect (handlerid);
                }
                handlerids.remove (handlerid);
            } else {
                warning ("MatchingTag: Tag: %s handlerid_remove: handlerid is 0", tag.pattern);
            }
        }

        public void disconnect_all () {
            // NOTE: Don't use native foreach
            handlerids.foreach ((item) => {
                handlerid_remove (item);
            });
        }

        ~MatchingTag () {
            message ("MatchingTag: Tag: %s destroyed", tag.pattern);
        }

        public void dump_to_console () {
            message ("MatchingTag: Tag: %s enabled: %s", tag.pattern, tag.enabled.to_string ());
            message ("\tHandlerids count: %u", handlerids.length ());
            foreach (var handlerid in handlerids) {
                message ("\t\tHandlerid: %lu", handlerid);
            }
        }
    }

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

        /* METHODS */

        public Tag? get_tag () {
            return mtag != null ? mtag.tag : null;
        }

        private void update_active_tag () {
            // If the current tag is enabled, we don't need to do anything
            message ("Line %u: update_active_tag called", number);

            if (mtag != null && mtag.tag.enabled) {
                message ("Line %u: current tag %s is enabled, no need to update active tag", number, mtag.tag.pattern);
                tag_changed ();
                return;
            }

            // Check if we have any enabled matching tags
            bool found = false;
            foreach (var tag in matching_tags) {
                if (tag.tag.enabled) {
                    found = true;
                    mtag = tag;
                    tag_changed ();
                    message ("Line %u: found enabled matching tag %s, setting as active tag", number, tag.tag.pattern);
                    break;
                }
            }

            if (!found && _mtag != null) {
                message ("Line %u: no enabled matching tags found, clearing active tag", number);
                mtag = null;
                tag_changed ();
            }
        }

        public void add_matching_tag (Tag tag) {
            message ("Add matching_tag (%s) to line %u", tag.pattern, number);
            var matching_tag = new MatchingTag (tag);
            if (matching_tags.find_custom (matching_tag, MatchingTag.matching_tag_compare) == null) {
                message ("Line %u: tag %s does not exist in matching tags", this.number, tag.pattern);
                matching_tag.handlerid_append (tag.changed.connect (() => {
                    message ("Line %u: tag changed : %s", this.number, tag.pattern);
                    update_active_tag ();
                }));

                matching_tag.handlerid_append (tag.enabled_changed.connect (() => {;
                    message ("Line %u: tag enabled_changed : %s", this.number, tag.pattern);
                    update_active_tag ();
                }));

                matching_tag.handlerid_append (tag.to_be_deleted.connect (() => {
                    message ("Line %u: tag to_be_removed : %s", this.number, tag.pattern);
                    remove_matching_tag (matching_tag);
                    update_active_tag ();
                }));

                matching_tags.append (matching_tag);
                update_active_tag ();
                message ("Line %u: tag %s added to matching tags", this.number, tag.pattern);
            }
        }

        public void remove_matching_tag (MatchingTag mtag) {
            if (matching_tags.find_custom (mtag, MatchingTag.matching_tag_compare) != null) {
                mtag.disconnect_all (); 
                matching_tags.remove (mtag);
                message ("Line %u: tag %s removed from matching tags", this.number, mtag.tag.pattern);
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
            /*
            for (uint i = 0; i < matching_tags.length (); i++) {
                var mtag = matching_tags.nth_data (i);
                remove_matching_tag (mtag);
            }
            */
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
