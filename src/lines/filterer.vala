/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * filterer.vala
 *
 * Class wrapper for Gtk.FilterListModel
 * Wraps a filtered model of the lines in a ListModel
 * 
 * - Depends on Tags.Filter to perform the filter match condition
 * - Needs a ListModel
 */

namespace Tags {
    public class Filterer : Object {
        public Lines lines;
        public Tags.Filter filter;
        public Gtk.FilterListModel model;

        public Filterer (Lines lines, Tags.Filter filter) {
            lines = lines;
            filter = filter;
            model = new Gtk.FilterListModel (lines.model, filter); 
            //model.set_incremental (true);
            //a changed connect to filter and have a signal
            //at the end of long task op.
        }

        public async void to_file (File file) {
            Line line;
            StringBuilder str;
            FileOutputStream fsout;

            str = new StringBuilder ();

            for (uint i = 0; i < model.get_n_items (); i++) {
                line = model.get_item (i) as Line;
                str.append_printf ("%s\n", line.text);
            }

            if (file.query_exists () == true) file.@delete ();

            try {
                fsout = yield file.replace_async (null, false, FileCreateFlags.REPLACE_DESTINATION); 
                yield fsout.write_all_async (str.str.data, Priority.DEFAULT, null, null);
                yield fsout.close_async (Priority.DEFAULT, null);
            } catch (Error e) {
                warning (e.message);
            }
        }
    }
}

