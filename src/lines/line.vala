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
        public List<ulong> handlerids;

        public static int matching_tag_compare (MatchingTag a, MatchingTag b) {
            MatchingTag mta = (MatchingTag) a;
            MatchingTag mtb = (MatchingTag) b;
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

        public bool handlerid_append (ulong handlerid) {
            message ("MatchingTag: Tag: %s handlerid_append: %lu", tag.pattern, handlerid);
            if (handlerid != 0) {
                message ("MatchingTag: Tag: %s handlerid_append [OK]: %lu", tag.pattern, handlerid);
                // NOTE: Update the List HEAD
                handlerids.append (handlerid);
                return true;
            }

            message ("MatchingTag: Tag: %s handlerid_append [FAILED]: %lu", tag.pattern, handlerid);
            return false;
        }

        public void handlerid_remove (ulong handlerid) {
            message ("MatchingTag: Tag: %s handlerid_remove: %lu", tag.pattern, handlerid);
            if (handlerids.find (handlerid) != null && handlerid != 0) {
                message ("MatchingTag: Tag: %s handlerid_remove [DISCONNECT OK]: %lu", tag.pattern, handlerid);
                tag.disconnect (handlerid);
            }
            message ("MatchingTag: Tag: %s handlerid_remove [OK]: %lu", tag.pattern, handlerid);
            handlerids.remove (handlerid);
        }

        public void disconnect_all () {
            // NOTE: Don't use foreach here, because we are
            // modifying the list while iterating over it
            for (uint i = 0; i < handlerids.length (); i++) {
                handlerid_remove (handlerids.nth_data (i));
            }
        }

        ~MatchingTag () {
            message ("MatchingTag: Tag: %s destroyed", tag.pattern);
        }
    }

    public class Line : Object {
        private Tag? _tag = null;
        private List<MatchingTag> matching_tags;

        public uint     number  { get; construct; }
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
            matching_tags = new List<MatchingTag> ();
        }

        /* METHODS */

        private reset_active_tag () {
            foreach (var mtag in matching_tags) {
                if (mtag.tag.enabled) {
                    this.tag = mtag.tag;
                    return this.tag;
                }
            }
            //message ("get_active_tag: Line %u no active tag found", number);
            return null;
        }

        public void add_matching_tag (Tag tag) {
            message ("Add matching_tag (%s) to line %u", tag.pattern, number);
            var matching_tag = new MatchingTag (tag);
            if (matching_tags.find_custom (matching_tag, MatchingTag.matching_tag_compare) == null) {

                matching_tag.handlerid_append (tag.changed.connect (() => {
                    message ("Line %u: tag changed : %s", this.number, tag.pattern);
                    get_active_tag ();
                }));

                matching_tag.handlerid_append (tag.enabled_changed.connect (() => {;
                    message ("Line %u: tag enabled_changed : %s", this.number, tag.pattern);
                    get_active_tag ();
                }));

                matching_tag.handlerid_append (tag.to_be_deleted.connect (() => {
                    message ("Line %u: tag to_be_removed : %s", this.number, tag.pattern);
                    remove_matching_tag (matching_tag);
                    get_active_tag ();
                }));

                matching_tags.append (matching_tag);
                get_active_tag ();
            }
        }

        public void remove_matching_tag (MatchingTag mtag) {
            if (matching_tags.find_custom (mtag, MatchingTag.matching_tag_compare) != null) {
                mtag.disconnect_all ();
                message ("Line %u: tag %s removed from matching tags", this.number, tag.pattern);
                matching_tags.remove (mtag);
                get_active_tag ();
            } else {
                warning ("Line %u: tag %s not found in matching tags", this.number, tag.pattern);
            }
        }

        public void clear_matching_tags () {
            // NOTE: Don't use foreach here, because we are
            // modifying the list while iterating over it
            for (uint i = 0; i < matching_tags.length (); i++) {
                var mtag = matching_tags.nth_data (i);
                remove_matching_tag (mtag);
            }
            /*
            foreach (var mtag in matching_tags) {
                remove_matching_tag (mtag);
            } 
            */
        }

        public void dump_to_console () {
            message ("Line %u: text: %s", number, text);
            message ("\tActive tag: %s", tag != null ? tag.pattern : "null");
            message ("\tMatching tags count: %u", matching_tags.length ());
            foreach (var mtag in matching_tags) {
                message ("\t\tTag [%s] enabled: %s", mtag.tag.pattern, mtag.tag.enabled.to_string ());
            }
        }
    }
}
