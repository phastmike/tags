public class TextMinimap : Gtk.DrawingArea {
    // File content
    private string[] lines = {};
    
    // Visual settings
    private int line_height = 3;
    private int padding = 4;
    private int width = 100;
    private Gdk.RGBA highlight_color;
    private Gdk.RGBA text_color;

    public const string rgba_dark_theme_hover   = "rgba (229, 229, 209, 0.25)";
    public const string rgba_light_theme_hover  = "rgba (26, 26, 26, 0.25)";

    public const string rgba_dark_theme_text    = "rgba (255, 255, 255, 0.25)";
    public const string rgba_light_theme_text   = "rgba (0, 0, 0, 0.25)";
    
    // Text view adjustment (for drawing the highlight)
    private Gtk.Adjustment? viewport_adjustment = null;
    
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

    public delegate void ViewportChangeFunc(double position_ratio);
    public ViewportChangeFunc? viewport_change_callback = null;

    /**
     * Structure to hold minimap metrics
     */
    private struct MiniMapMetrics {
        public double total_minimap_height;   // Total height of the minimap content
        public double document_to_minimap_ratio; // Ratio between document and minimap
        public double minimap_to_document_ratio; // Ratio between minimap and document
        public double viewport_y;             // Y position of viewport in minimap
        public double viewport_height;        // Height of viewport in minimap
    }

    public TextMinimap (Gtk.Adjustment text_adj = null) {
        Object();

        set_viewport_adjustment (text_adj);


        init_colors ();
        reset_colors ();


        set_draw_func(draw);
        set_size_request(width, -1);

        init_gestures ();
    }

    private void clear () {
        lines = {};
    }

    private void init_colors () {
        highlight_color = Gdk.RGBA ();
        text_color = Gdk.RGBA ();

        var sm = Adw.StyleManager.get_default ();
        sm.notify["dark"].connect ( () => {
            message ("Reset colors ...");
            reset_colors ();
        });
    }

    private void reset_colors () {
        Adw.StyleManager style_manager = Adw.StyleManager.get_default ();
        var is_dark = style_manager.get_dark ();
        if (is_dark) {
            highlight_color.parse (rgba_dark_theme_hover);
            text_color.parse (rgba_dark_theme_text);
        } else {
            highlight_color.parse (rgba_dark_theme_hover);
            text_color.parse (rgba_dark_theme_text);
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
     * Set callback function for viewport changes
     */
    public void set_viewport_change_callback(ViewportChangeFunc callback) {
        viewport_change_callback = callback;
    }
    
    public void load_file(string content) {
        var file_content = content;
        lines = file_content.split("\n");
        
        int total_height = lines.length * line_height;
        set_size_request(width, total_height);
        
        queue_draw();
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
        value = double.max(viewport_adjustment.get_lower(), 
                         double.min(value, viewport_adjustment.get_upper() - viewport_adjustment.get_page_size()));
        
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
        //metrics.total_minimap_height = get_height ();
        
        // Calculate document height (from adjustment)
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
        double indicator_y = (metrics.total_minimap_height - indicator_height) * scroll_ratio;

        // metrics.viewport_y = indicator_y;
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
        new_value = double.max(viewport_adjustment.get_lower(), 
                             double.min(new_value, viewport_adjustment.get_upper() - viewport_adjustment.get_page_size()));
        
        // Set target value for animation
        target_value = new_value;
        
        // Start animation if not already running
        if (animation_source_id == 0) {
            animation_source_id = Timeout.add(32, animate_viewport);
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
    

    private Gdk.RGBA get_default_hover_color() {
        Gdk.RGBA color = Gdk.RGBA ();
        Adw.StyleManager style_manager = Adw.StyleManager.get_default ();
        var is_dark = style_manager.get_dark ();
        if (is_dark)
            color.parse (rgba_dark_theme_hover);
        else
            color.parse (rgba_light_theme_hover);
        return color;
    }

    private Gdk.RGBA get_default_text_color() {
        Gdk.RGBA color = Gdk.RGBA ();
        Adw.StyleManager style_manager = Adw.StyleManager.get_default ();
        var is_dark = style_manager.get_dark ();
        if (is_dark)
            color.parse ("rgba (255, 255, 255, 0.25)");
        else
            color.parse ("rgba(0, 0, 0, 0.25)");
        return color;
    }

    public void set_line_color_bg_callback (GetLineColorBgFunc? callback) {
        get_default_text_color_bg_callback = callback;
    }
    
    private void draw(Gtk.DrawingArea da, Cairo.Context cr, int width, int height) {
        if (lines.length == 0) {
            return;
        }
        
        // Calculate all metrics for consistent rendering
        MiniMapMetrics metrics = calculate_metrics();
        
        // Draw the text representation with syntax highlighting
        for (int i = 0; i < lines.length; i++) {
            // Calculate line position
            double y = i * line_height;
            
            // Skip if outside visible area (with some margin)
            if (y > height + 10) {
                break;
            }
            
            if (y < -10) {
                continue;
            }
            
            // Set color based on line content (tag background color)
            var bg_color = get_default_text_color_bg_callback (lines[i]) ?? text_color;
            Gdk.cairo_set_source_rgba(cr, bg_color);
            
            // Draw line representation based on content length
            double line_width = double.min(width - padding * 2, lines[i].length * 0.5);
            if (line_width > 0) {
                cr.rectangle(padding, y + padding/2, line_width, line_height - padding);
                cr.fill();
            }
        }
        
        // Draw hover indicator if mouse is over the widget
        if (hover_y != null && !dragging && hover_y < (line_height * lines.length)) {
            cr.set_source_rgba(0.8, 0.8, 0.9, 0.3);
            cr.rectangle(0, hover_y, width, line_height);
            cr.fill();
        }
        
        //highlight_color = get_default_hover_color ();

        // Draw the viewport highlight
        if (dragging && dragging_viewport) {
            highlight_color.alpha = 0.35f;
        } else if (hover_y != null && hover_y < lines.length * line_height) {
            highlight_color.alpha = 0.30f;
        } else {
            highlight_color.alpha = 0.25f;
        }

        Gdk.cairo_set_source_rgba(cr, highlight_color);
        cr.rectangle(0, metrics.viewport_y, width, metrics.viewport_height);
        cr.fill();

        highlight_color.alpha = 0.75f;
        cr.set_line_width(1);
        cr.rectangle(0, metrics.viewport_y, width, metrics.viewport_height);
        cr.stroke();
    }
}
