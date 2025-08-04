/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * minimap-scroll-manager.vala
 *
 * Main application Window class
 *
 * José Miguel Fonte
 */

public class MinimapScrollManager : GLib.Object {

    private Gtk.Adjustment adj_text;
    private Gtk.Adjustment adj_minimap;
    
    public MinimapScrollManager(Gtk.ScrolledWindow scr_text, Gtk.ScrolledWindow scr_minimap) {
        adj_text = scr_text.get_vadjustment ();
        adj_minimap = scr_minimap.get_vadjustment ();

        adj_text.bind_property (
            "value", 
            adj_minimap, 
            "value", 
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
            (
                (b, from_value, ref to_value) => {
                    if (adj_text.get_upper () <= 0) return false;
                    double t1 = from_value.get_double () / (adj_text.get_upper () - adj_text.get_page_size ());
                    double t2 = adj_minimap.get_upper () - adj_minimap.get_page_size ();
                    to_value.set_double (t1 * t2);
                    return true;
                }
            ),
            (
                (b, from_value, ref to_value) => {
                    if (adj_text.get_upper () <= 0) return false;
                    double t1 = from_value.get_double () / (adj_minimap.get_upper () - adj_minimap.get_page_size ());
                    double t2 = adj_text.get_upper () - adj_text.get_page_size ();
                    to_value.set_double (t1 * t2); 
                    return true;
                }
            )
        );
    }
}
