public class MinimapScrollManager : GLib.Object {
    private TextMinimap minimap;
    private Gtk.ScrolledWindow text_scrolled;
    private Gtk.ScrolledWindow minimap_scrolled;
    
    private bool syncing = false;
    
    public MinimapScrollManager(Gtk.ScrolledWindow text_scrolled,
                         TextMinimap minimap, Gtk.ScrolledWindow minimap_scrolled) {
        this.text_scrolled = text_scrolled;
        this.minimap = minimap;
        this.minimap_scrolled = minimap_scrolled;
        
        minimap.set_viewport_adjustment(text_scrolled.get_vadjustment());
        minimap.set_viewport_change_callback(on_minimap_viewport_change);
        text_scrolled.get_vadjustment().value_changed.connect(on_text_scroll_changed);
        
        Idle.add(() => {
            sync_minimap_scroll_to_text();
            return false;
        });
    }
    
    private void on_minimap_viewport_change(double position_ratio) {
        if (!syncing) {
            syncing = true;
            sync_minimap_scroll_to_text();
            syncing = false;
        }
    }
    
    private void on_text_scroll_changed() {
        if (!syncing) {
            syncing = true;
            sync_minimap_scroll_to_text();
            syncing = false;
        }
    }
    
    private void sync_minimap_scroll_to_text() {
        var text_adj = text_scrolled.get_vadjustment();
        var minimap_adj = minimap_scrolled.get_vadjustment();

        double document_height = text_adj.get_upper() - text_adj.get_lower() - text_adj.get_page_size();
        double document_position = text_adj.get_value() / document_height;
        
        double minimap_height = minimap_adj.get_upper() - minimap_adj.get_lower() - minimap_adj.get_page_size();
        double minimap_position = document_position * minimap_height;
        
        minimap_adj.set_value(minimap_position);
        minimap.get_viewport_adjustment ().set_value (text_adj.get_value () / document_height);
        //minimap_scrolled.get_vadjustment ().set_value (minimap_position);
    }
}
