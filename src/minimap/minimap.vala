/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * minimap.vala
 *
 * Minimap widget
 *
 * José Miguel Fonte
 */

public class Minimap : Gtk.Box {
    private string[] lines = {};
    
    private int line_height = 3;
    private int padding = 4;
    private int width = 100;
    private Gdk.RGBA highlight_color;
    private Gdk.RGBA text_color;

    public const string rgba_dark_theme_hover   = "rgba (229, 229, 209, 0.25)";
    public const string rgba_light_theme_hover  = "rgba (26, 26, 26, 0.25)";

    public const string rgba_dark_theme_text    = "rgba (221, 221, 222, 0.15)";
    public const string rgba_light_theme_text   = "rgba (0, 0, 0, 0.15)";
    
    public Gtk.DrawingArea drawing_area;
    public Gtk.ScrolledWindow scrolled_window;                  // Has own viewport adjustment
    private Gtk.Adjustment? external_adj = null;                // External viewport vertical adjustment
    private Cairo.RecordingSurface? minimap_cached = null;      // Cache for minimap rendering
    
    // Mouse interaction state
    private bool dragging = false;
    private bool dragging_viewport = false;
    private double drag_start_y = 0;
    private double drag_start_value = 0;
    private double? hover_y = null;
    private uint animation_source_id = 0;
    private double? target_value = null;
    
    // Delegates
    public delegate Gdk.RGBA? GetLineColorBgFunc (string? text);
    public GetLineColorBgFunc? get_default_text_color_bg_callback = null;

    // Structure to hold minimap metrics
    private struct MiniMapMetrics {
        public double total_minimap_height;         // Total height of the minimap content
        public double document_to_minimap_ratio;    // Ratio between document and minimap
        public double minimap_to_document_ratio;    // Ratio between minimap and document
        public double viewport_y;                   // Y position of viewport in minimap
        public double viewport_height;              // Height of viewport in minimap
    }

    public Minimap (Gtk.Adjustment? adj = null) {
        Object (orientation: Gtk.Orientation.VERTICAL, spacing: 0);
        set_vexpand (true);

        var sm = Adw.StyleManager.get_default ();
        sm.notify["dark"].connect ( () => {
            reset_colors ();
            redraw_lines ();
        });

        drawing_area = new Gtk.DrawingArea ();
        init_colors ();
        reset_colors ();
        drawing_area.set_size_request (0, -1);
        drawing_area.set_content_width (width);
        drawing_area.set_draw_func (draw);
        init_gestures ();

        scrolled_window = new Gtk.ScrolledWindow ();
        scrolled_window.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.EXTERNAL);
        scrolled_window.set_child (drawing_area);
        scrolled_window.set_vexpand (true);

        append (scrolled_window);
        set_external_adj (adj);
    }

    public void clear () {
        lines = {};
        redraw_lines ();
    }

    private bool get_theme_is_dark () {
        Adw.StyleManager style_manager = Adw.StyleManager.get_default ();
        return style_manager.get_dark ();  
    }

    private void init_colors () {
        highlight_color = Gdk.RGBA ();
        text_color = Gdk.RGBA ();
    }

    private void reset_colors () {
        if (get_theme_is_dark ()) {
            highlight_color.parse (rgba_dark_theme_hover);
            text_color.parse (rgba_dark_theme_text);
        } else {
            highlight_color.parse (rgba_light_theme_hover);
            text_color.parse (rgba_light_theme_text);
        }
    }

    private void init_gestures () {
        // Left mouse button
        var click_gesture = new Gtk.GestureClick ();
        click_gesture.set_button (1);
        click_gesture.pressed.connect (on_button_press);
        click_gesture.released.connect (on_button_release);
        drawing_area.add_controller (click_gesture);

        // Drag
        var drag_gesture = new Gtk.GestureDrag ();
        drag_gesture.drag_begin.connect (on_drag_begin);
        drag_gesture.drag_update.connect (on_drag_update);
        drag_gesture.drag_end.connect (on_drag_end);
        drawing_area.add_controller (drag_gesture);

        // Motion for hover effects
        var motion_controller = new Gtk.EventControllerMotion ();
        motion_controller.motion.connect (on_motion);
        motion_controller.leave.connect (on_leave);
        drawing_area.add_controller (motion_controller);
    }

    public Gtk.Adjustment? get_external_adj () {
        return external_adj;
    }
    
    public void set_external_adj (Gtk.Adjustment? adj) {
        if (external_adj != null) {
            external_adj.value_changed.disconnect (drawing_area.queue_draw);
        }
        
        external_adj = adj;

        if (external_adj != null) {
            var adj_minimap = scrolled_window.get_vadjustment ();

            external_adj.bind_property (
                "value", 
                adj_minimap, 
                "value", 
                BindingFlags.SYNC_CREATE, // | BindingFlags.BIDIRECTIONAL,
                (
                    (b, from_value, ref to_value) => {
                        if (external_adj.get_upper () <= 0) return false;
                        double t1 = from_value.get_double () / (external_adj.get_upper () - external_adj.get_page_size ());
                        double t2 = adj_minimap.get_upper () - adj_minimap.get_page_size ();
                        to_value.set_double (t1 * t2);
                        return true;
                    }
                ),
                (
                    (b, from_value, ref to_value) => {
                        if (external_adj.get_upper () <= 0) return false;
                        double t1 = from_value.get_double () / (adj_minimap.get_upper () - adj_minimap.get_page_size ());
                        double t2 = external_adj.get_upper () - external_adj.get_page_size ();
                        to_value.set_double (t1 * t2); 
                        return true;
                    }
                )
            );

            external_adj.value_changed.connect (drawing_area.queue_draw);
        }

        drawing_area.queue_draw();
    }
    
    private void redraw_lines () {
        Gdk.RGBA bg_color;

        minimap_cached = null;

        int height = lines.length * line_height;

        if (height == 0) return;

        drawing_area.set_size_request(width, height);

        var bounds = Cairo.Rectangle ();
        bounds.x = 0; bounds.y = 0; bounds.width = width; bounds.height = height;
        minimap_cached = new Cairo.RecordingSurface (Cairo.Content.COLOR_ALPHA, bounds);

        var cr = new Cairo.Context (minimap_cached);

        if (cr == null) return;

        for (int i = 0; i < lines.length; i++) {
            double y = i * line_height;

            if (y > height + 10) {
                break;
            }

            if (y < -10) {
                continue;
            }

            if (get_default_text_color_bg_callback != null) {
                bg_color = get_default_text_color_bg_callback (lines[i]) ?? text_color;
            } else {
                bg_color = text_color;
            }

            Gdk.cairo_set_source_rgba (cr, bg_color);

            double line_width = Math.fmin (width - (padding * 2), lines[i].length * 0.5);
            if (line_width > 0) {
                cr.rectangle(padding, y + (padding / 2), line_width, line_height - padding);
                cr.fill();
            }
        }
    }
    
    // FIXME: Rename. This is not really setting an array, but updating the content of the minimap.
    public void set_array (string[] lines) {
        this.lines = lines;
        redraw_lines ();
        drawing_area.queue_draw ();
    }

    private void on_motion(double x, double y) {
        hover_y = y;
        drawing_area.queue_draw ();
    }
    
    private void on_leave () {
        hover_y = null;
        drawing_area.queue_draw ();
    }
    
    private void on_button_press (int n_press, double x, double y) {
        cancel_animations ();
        
        MiniMapMetrics metrics = calculate_metrics ();
        
        if (y >= metrics.viewport_y && y <= metrics.viewport_y + metrics.viewport_height) {
            dragging_viewport = true;
            drag_start_value = external_adj != null ? external_adj.get_value() : scrolled_window.get_vadjustment ().get_value ();
        } else {
            dragging_viewport = false;
            update_viewport_from_y (y);
        }
    }
    
    private void on_button_release (int n_press, double x, double y) {
        dragging_viewport = false;
    }
    
    private void on_drag_begin (double start_x, double start_y) {
        dragging = true;
        drag_start_y = start_y;
        drag_start_value = external_adj != null ? external_adj.get_value() : scrolled_window.get_vadjustment ().get_value ();
        cancel_animations ();
    }
    
    private void on_drag_update (double offset_x, double offset_y) {
        if (!dragging) {
            return;
        }
        
        MiniMapMetrics metrics = calculate_metrics ();
        
        if (dragging_viewport) {
            // Convert drag offset to document offset
            double document_offset = offset_y / metrics.document_to_minimap_ratio;
            double new_value = drag_start_value + document_offset;
            
            update_external_adj (new_value);
        } else {
            // Update based on absolute position
            update_viewport_from_y (drag_start_y + offset_y);
        }
    }
    
    private void on_drag_end (double offset_x, double offset_y) {
        dragging = false;
        dragging_viewport = false;
    }
    
    private void update_external_adj (double value) {
        Gtk.Adjustment adj = external_adj;
        value = Math.fmax (adj.get_lower(), Math.fmin (value, adj.get_upper () - adj.get_page_size ()));
        adj.set_value (value);
    }
    
    private void cancel_animations () {
        if (animation_source_id > 0) {
            Source.remove (animation_source_id);
            animation_source_id = 0;
        }
        
        target_value = null;
    }
    
    private MiniMapMetrics calculate_metrics() {
        MiniMapMetrics metrics = MiniMapMetrics ();
        
        metrics.total_minimap_height = lines.length * line_height;

        double document_height = external_adj.get_upper () - external_adj.get_lower ();
        
        // Calculate ratio between document and minimap
        metrics.document_to_minimap_ratio = document_height > 0 ?
                                          metrics.total_minimap_height / document_height : 1.0;
        metrics.minimap_to_document_ratio = metrics.document_to_minimap_ratio > 0 ?
                                          1.0 / metrics.document_to_minimap_ratio : 1.0;

        // Calculate viewport position and size in minimap coordinates
        metrics.viewport_y = external_adj.get_value () * metrics.document_to_minimap_ratio;
        metrics.viewport_height = external_adj.get_page_size () * metrics.document_to_minimap_ratio;
  
        // Ensure viewport is visible even for very small ratios
        metrics.viewport_height = Math.fmax (metrics.viewport_height, 5);
        
        return metrics;
    }
    
    private void update_viewport_from_y(double y) {
        MiniMapMetrics metrics = calculate_metrics ();
        
        // Convert minimap position to document position
        double document_position = y * metrics.minimap_to_document_ratio;
        
        // Center the viewport around the clicked position if possible
        double half_viewport = external_adj.get_page_size () / 2;
        double new_value = document_position - half_viewport;
        
        // Apply animation for smooth scrolling
        animate_to_value (new_value);
    }
    
    // Animate to a specific adjustment value
    private void animate_to_value (double new_value) {
        // Ensure bounds
        new_value = Math.fmax (external_adj.get_lower (),
                             Math.fmin (new_value,
                             external_adj.get_upper () - external_adj.get_page_size ()));

        // Set target value for animation
        target_value = new_value;

        // Start animation if not already running
        if (animation_source_id == 0) {
            animation_source_id = Timeout.add (8, animate_viewport);
        }
    }
    
    // Animate viewport movement for smooth scrolling
    private bool animate_viewport() {
        if (target_value == null) {
            animation_source_id = 0;
            return false;
        }
        
        // Calculate step size (easing function)
        double diff = target_value - external_adj.get_value ();
        if (Math.fabs (diff) < 1.0) {
            // We're close enough, snap to target
            update_external_adj (target_value);
            
            target_value = null;
            animation_source_id = 0;
            return false;
        }
        
        // Move toward target with easing
        double step = diff * 0.3;
        double new_value = external_adj.get_value () + step;
        
        // Update adjustment value
        update_external_adj (new_value);
        
        return true;
    }
    
    public void set_line_color_bg_callback (GetLineColorBgFunc? callback) {
        get_default_text_color_bg_callback = (GetLineColorBgFunc?) callback;
    }
    
    private void draw (Gtk.DrawingArea da, Cairo.Context cr, int width, int height) {
        if (lines.length == 0) {
            return;
        }

        MiniMapMetrics metrics = calculate_metrics ();

        if (minimap_cached != null) {
            cr.set_source_surface (minimap_cached, 0, 0);
            cr.paint ();
        }

        // Draw hover indicator if mouse is over the widget
        if (hover_y != null && !dragging && hover_y < (line_height * lines.length)) {
            cr.set_source_rgba (0.8, 0.8, 0.9, 0.3);
            cr.rectangle (0, hover_y, width, line_height);
            cr.fill();
        }

        // Draw the viewport highlight
        if (external_adj != null & dragging && dragging_viewport) {
            highlight_color.alpha = 0.25f;
        } else if (hover_y != null && hover_y < lines.length * line_height) {
            highlight_color.alpha = 0.20f;
        } else {
            highlight_color.alpha = 0.15f;
        }

        Gdk.cairo_set_source_rgba (cr, highlight_color);
        cr.rectangle (0, metrics.viewport_y, width, metrics.viewport_height);
        cr.fill ();

        /*
        // Viewport border
        highlight_color.alpha = 0.75f;
        cr.set_line_width(2);
        cr.rectangle(0, metrics.viewport_y, width, metrics.viewport_height);
        cr.stroke();
        */
    }
}
