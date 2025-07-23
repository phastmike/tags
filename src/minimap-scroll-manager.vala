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
                    var h1 = adj_text.get_upper () - adj_text.get_lower ();
                    var h2 = adj_minimap.get_upper () - adj_minimap.get_lower ();

                    double t1 = from_value.get_double () / (adj_text.get_upper () - adj_text.get_page_size ());
                    double t2 = adj_minimap.get_upper () - adj_minimap.get_page_size ();
                    double t3 = t1 * t2;
                    to_value.set_double (t3);

                    /*
                    double t1 = from_value.get_double () - (adj_text.get_upper () / 2);
                    double t2 = (t1 * (adj_minimap.get_upper () / adj_text.get_upper ())) + (adj_minimap.get_value () / 2);

                    to_value.set_double (t2);
                    */


                    /*
                    double r1 = h1/h2;
                    double p1 = adj_text.get_value () / adj_text.get_upper ();
                    message ("M1 h1 = %f h2 = %f rr = %f", h1, h2, (adj_text.get_value () / adj_text.get_upper ()));
                    message ("hp2 = %f", p1 * adj_minimap.get_upper ());
                    message ("value = %f", (from_value.get_double () + (adj_text.get_page_size () / h2)));
                    //to_value.set_double (from_value.get_double () / (h1 / h2));
                    to_value.set_double (p1 * adj_minimap.get_upper ());
                    //to_value.set_double (from_value.get_double () * (adj_text.get_page_size () / h2));
                    */
                    return true;
                }
            ),
            (
                (b, from_value, ref to_value) => {
                    if (adj_text.get_upper () <= 0) return false;
                    double h1 = adj_text.get_upper () - adj_text.get_lower ();
                    double h2 = adj_minimap.get_upper () - adj_minimap.get_lower ();
                    double ratio = (h2 / h1);
                    message ("M2 h1 = %f h2 = %f ps = %f value = %f", h1, h2, adj_text.get_page_size (), adj_text.get_page_size ());
                    to_value.set_double (from_value.get_double () / ratio); 
                    return true;
                }
            )
        );
    }
}
