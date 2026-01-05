/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * minimap.vala
 *
 * Minimap widget
 *
 * José Miguel Fonte
 */

public class Minimap : Gtk.DrawingArea {
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
    
    // Text view adjustment (for drawing the highlight)
    private Gtk.Adjustment? viewport_adjustment = null;

    private Cairo.RecordingSurface? minimap_cached = null;
    
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

    public delegate void ViewportChangeFunc (double position_ratio);
    public ViewportChangeFunc? viewport_change_callback = null;

    /**
     * Structure to hold minimap metrics
     */
    private struct MiniMapMetrics {
        public double total_minimap_height;         // Total height of the minimap content
        public double document_to_minimap_ratio;    // Ratio between document and minimap
        public double minimap_to_document_ratio;    // Ratio between minimap and document
        public double viewport_y;                   // Y position of viewport in minimap
        public double viewport_height;              // Height of viewport in minimap
    }

    public Minimap (Gtk.Adjustment? text_adj = null) {
        Object();

        set_viewport_adjustment (text_adj);

        init_colors ();
        reset_colors ();

        set_size_request (0, -1);
        set_content_width (width);
        set_draw_func (draw);

        init_gestures ();
    }

    public void clear () {
        lines = {};
        cairo_surface_record_lines ();
    }

    private bool get_theme_is_dark () {
        Adw.StyleManager style_manager = Adw.StyleManager.get_default ();
        return style_manager.get_dark ();  
    }

    private void init_colors () {
        highlight_color = Gdk.RGBA ();
        text_color = Gdk.RGBA ();

        var sm = Adw.StyleManager.get_default ();
        sm.notify["dark"].connect ( () => {
            reset_colors ();
            cairo_surface_record_lines ();
        });
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
        var click_gesture = new Gtk.GestureClick();
        click_gesture.set_button(1);
        click_gesture.pressed.connect(on_button_press);
        click_gesture.released.connect(on_button_release);
        add_controller(click_gesture);

        // Drag
        var drag_gesture = new Gtk.GestureDrag();
        drag_gesture.drag_begin.connect(on_drag_begin);
        drag_gesture.drag_update.connect(on_drag_update);
        drag_gesture.drag_end.connect(on_drag_end);
        add_controller(drag_gesture);

        // Motion for hover effects
        var motion_controller = new Gtk.EventControllerMotion();
        motion_controller.motion.connect(on_motion);
        motion_controller.leave.connect(on_leave);
        add_controller(motion_controller);
    }

    public Gtk.Adjustment? get_viewport_adjustment() {
        return viewport_adjustment;
    }
    
    public void set_viewport_adjustment(Gtk.Adjustment? adj) {
        if (viewport_adjustment != null) {
            viewport_adjustment.value_changed.disconnect(queue_draw);
        }
        
        viewport_adjustment = adj;

        if (adj != null) {
            viewport_adjustment.value_changed.connect(queue_draw);
        }

        queue_draw();
    }
    
    /**
     * FIXME: NOT BEING USED - REMOVE but check usage for the callback
     */
    /*
    public void set_viewport_change_callback(ViewportChangeFunc callback) {
        viewport_change_callback = callback;
    }
    */

    private void cairo_surface_record_lines () {
        minimap_cached = null;

        int height = lines.length * line_height;

        if (height == 0) return;

        set_size_request(width, height);

        var bounds = Cairo.Rectangle ();
        bounds.x = 0; bounds.y = 0; bounds.width = width; bounds.height = height;
        minimap_cached = new Cairo.RecordingSurface (Cairo.Content.COLOR_ALPHA, bounds);
        //minimap_cached = new Cairo.RecordingSurface (Cairo.Content.COLOR_ALPHA);

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

            Gdk.RGBA bg_color = text_color;
            if (get_default_text_color_bg_callback != null) {
                bg_color = get_default_text_color_bg_callback (lines[i]) ?? text_color;
            }

            Gdk.cairo_set_source_rgba(cr, bg_color);

            double line_width = Math.fmin (width - (padding * 2), lines[i].length * 0.5);
            if (line_width > 0) {
                cr.rectangle(padding, y + (padding / 2), line_width, line_height - padding);
                cr.fill();
            }
        }
    }
    
    public void set_array (string[] lines) {
        this.lines = lines;
        cairo_surface_record_lines ();
        queue_draw ();
    }

    private void on_motion(double x, double y) {
        hover_y = y;
        queue_draw();
    }
    
    private void on_leave() {
        hover_y = null;
        queue_draw();
    }
    
    private void on_button_press(int n_press, double x, double y) {
        cancel_animations();
        
        MiniMapMetrics metrics = calculate_metrics();
        
        if (y >= metrics.viewport_y && y <= metrics.viewport_y + metrics.viewport_height) {
            dragging_viewport = true;
            drag_start_value = viewport_adjustment.get_value();
        } else {
            dragging_viewport = false;
            // Update viewport immediately on click outside viewport
            update_viewport_from_y(y);
        }
    }
    
    private void on_button_release(int n_press, double x, double y) {
        dragging_viewport = false;
    }
    
    private void on_drag_begin(double start_x, double start_y) {
        dragging = true;
        drag_start_y = start_y;
        drag_start_value = viewport_adjustment.get_value();
        
        // Cancel any ongoing animation
        cancel_animations();
    }
    
    private void on_drag_update(double offset_x, double offset_y) {
        if (!dragging) {
            return;
        }
        
        MiniMapMetrics metrics = calculate_metrics();
        
        if (dragging_viewport) {
            // Convert drag offset to document offset
            double document_offset = offset_y / metrics.document_to_minimap_ratio;
            double new_value = drag_start_value + document_offset;
            
            // Update text adjustment value
            update_viewport_adjustment(new_value);
        } else {
            // Update based on absolute position
            update_viewport_from_y(drag_start_y + offset_y);
        }
    }
    
    private void on_drag_end(double offset_x, double offset_y) {
        dragging = false;
        dragging_viewport = false;
    }
    
    private void update_viewport_adjustment(double value) {
        // Ensure bounds
        value = Math.fmax(viewport_adjustment.get_lower(),
                         Math.fmin(value, viewport_adjustment.get_upper() - viewport_adjustment.get_page_size()));
        
        viewport_adjustment.set_value(value);
        
        // Notify about viewport change
        if (viewport_change_callback != null) {
            double document_height = viewport_adjustment.get_upper() - viewport_adjustment.get_lower() - viewport_adjustment.get_page_size();
            double position_ratio = value / document_height;
            viewport_change_callback(position_ratio);
        }
    }
    
    private void cancel_animations() {
        if (animation_source_id > 0) {
            Source.remove(animation_source_id);
            animation_source_id = 0;
        }
        
        target_value = null;
    }
    
    private MiniMapMetrics calculate_metrics() {
        MiniMapMetrics metrics = MiniMapMetrics();
        
        metrics.total_minimap_height = lines.length * line_height;

        double document_height = viewport_adjustment.get_upper() - viewport_adjustment.get_lower();
        
        // Calculate ratio between document and minimap
        metrics.document_to_minimap_ratio = document_height > 0 ?
                                          metrics.total_minimap_height / document_height : 1.0;
        metrics.minimap_to_document_ratio = metrics.document_to_minimap_ratio > 0 ?
                                          1.0 / metrics.document_to_minimap_ratio : 1.0;

        // Calculate viewport position and size in minimap coordinates

        metrics.viewport_y = viewport_adjustment.get_value() * metrics.document_to_minimap_ratio;

        double ratio = viewport_adjustment.get_page_size () / document_height;
        double indicator_height = metrics.total_minimap_height * ratio;
        double scroll_ratio = viewport_adjustment.get_value () / (document_height - viewport_adjustment.get_page_size ());
        //double indicator_y = (metrics.total_minimap_height - indicator_height) * scroll_ratio;

        metrics.viewport_height = viewport_adjustment.get_page_size() * metrics.document_to_minimap_ratio;
  
        // Ensure viewport is visible even for very small ratios
        metrics.viewport_height = Math.fmax(metrics.viewport_height, 5);
        
        return metrics;
    }
    
    private void update_viewport_from_y(double y) {
        MiniMapMetrics metrics = calculate_metrics();
        
        // Convert minimap position to document position
        double document_position = y * metrics.minimap_to_document_ratio;
        
        // Center the viewport around the clicked position if possible
        double half_viewport = viewport_adjustment.get_page_size() / 2;
        double new_value = document_position - half_viewport;
        
        // Apply animation for smooth scrolling
        animate_to_value(new_value);
    }
    
    /**
     * Animate to a specific adjustment value
     */
    private void animate_to_value(double new_value) {
        // Ensure bounds
        new_value = Math.fmax(viewport_adjustment.get_lower(),
                             Math.fmin(new_value,
                             viewport_adjustment.get_upper() - viewport_adjustment.get_page_size()));

        // Set target value for animation
        target_value = new_value;

        // Start animation if not already running
        if (animation_source_id == 0) {
            animation_source_id = Timeout.add(8, animate_viewport);
        }
    }
    
    /**
     * Animate viewport movement for smooth scrolling
     */
    private bool animate_viewport() {
        if (target_value == null) {
            animation_source_id = 0;
            return false;
        }
        
        // Calculate step size (easing function)
        double diff = target_value - viewport_adjustment.get_value();
        if (Math.fabs(diff) < 1.0) {
            // We're close enough, snap to target
            update_viewport_adjustment(target_value);
            
            target_value = null;
            animation_source_id = 0;
            return false;
        }
        
        // Move toward target with easing
        double step = diff * 0.3;
        double new_value = viewport_adjustment.get_value() + step;
        
        // Update adjustment value
        update_viewport_adjustment(new_value);
        
        return true;
    }
    
    public void set_line_color_bg_callback (GetLineColorBgFunc? callback) {
        get_default_text_color_bg_callback = (GetLineColorBgFunc?) callback;
    }
    
    private void draw(Gtk.DrawingArea da, Cairo.Context cr, int width, int height) {
        if (lines.length == 0) {
            return;
        }

        MiniMapMetrics metrics = calculate_metrics();

        if (minimap_cached != null) {
            cr.set_source_surface (minimap_cached, 0, 0);
            cr.paint ();
        }

        // Draw hover indicator if mouse is over the widget
        if (hover_y != null && !dragging && hover_y < (line_height * lines.length)) {
            cr.set_source_rgba(0.8, 0.8, 0.9, 0.3);
            cr.rectangle(0, hover_y, width, line_height);
            cr.fill();
        }

        // Draw the viewport highlight
        if (dragging && dragging_viewport) {
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
        highlight_color.alpha = 0.75f;
        cr.set_line_width(1);
        cr.rectangle(0, metrics.viewport_y, width, metrics.viewport_height);
        cr.stroke();
        */
    }
}
