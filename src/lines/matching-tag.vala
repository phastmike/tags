/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * matching-tag.vala
 *
 * Class for Line's matching Tags
 *
 * José Miguel Fonte
 */

namespace Tags {
    public class MatchingTag : Object {
        public Tag tag {get; construct;}
        private List<ulong> handlerids;

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
            // NOTE: Don't use native Vala foreach. 
            handlerids.foreach ((item) => {
                handlerid_remove (item);
            });
        }
    }
}

