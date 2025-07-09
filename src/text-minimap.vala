public class TextMinimap : Gtk.DrawingArea {
    // File content
    private string file_content = "";
    private string[] lines = {};
    
    // Visual settings
    private int line_height = 2;
    private int padding = 4;
    private Gdk.RGBA highlight_color;
    private Gdk.RGBA text_color;
    private Gdk.RGBA keyword_color;
    private Gdk.RGBA string_color;
    private Gdk.RGBA comment_color;
    private Gdk.RGBA hover_color;
    private Gdk.RGBA drag_color;
    
    // Current viewport information (in pixels)
    private double viewport_start_ratio = 0;  // Position as ratio (0-1) of document height
    private double viewport_height_ratio = 0; // Height as ratio (0-1) of document height
    
    // Mouse interaction state
    private bool dragging = false;
    private bool dragging_viewport = false;
    private double drag_start_y = 0;
    private double drag_start_ratio = 0;
    private double? hover_y = null;
    private uint animation_source_id = 0;
    private double? target_viewport_ratio = null;
    
    // Scroll physics
    private double last_drag_time = 0;
    private double last_drag_y = 0;
    private double drag_velocity = 0;
    private uint momentum_scroll_id = 0;
    
    // Regular expressions for syntax highlighting
    private Regex keyword_pattern;
    private Regex string_pattern;
    private Regex comment_pattern;
    
    // Callback for viewport changes
    public delegate void ViewportChangeFunc(double position_ratio);
    public ViewportChangeFunc? viewport_change_callback = null;
    
    public TextMinimap() {
        Object();
        
        // Initialize colors
        highlight_color = Gdk.RGBA();
        highlight_color.parse("rgba(179, 179, 204, 0.5)");
        
        text_color = Gdk.RGBA();
        text_color.parse("rgba(77, 77, 77, 0.8)");
        
        keyword_color = Gdk.RGBA();
        keyword_color.parse("rgba(51, 102, 153, 0.8)");
        
        string_color = Gdk.RGBA();
        string_color.parse("rgba(153, 77, 51, 0.8)");
        
        comment_color = Gdk.RGBA();
        comment_color.parse("rgba(102, 153, 102, 0.8)");
        
        hover_color = Gdk.RGBA();
        hover_color.parse("rgba(204, 204, 230, 0.3)");
        
        drag_color = Gdk.RGBA();
        drag_color.parse("rgba(179, 179, 255, 0.7)");
        
        // Initialize regular expressions
        try {
            keyword_pattern = new Regex("\\b(def|class|import|from|if|else|elif|for|while|return|try|except|with)\\b");
            string_pattern = new Regex("(\".*?\"|'.*?')");
            comment_pattern = new Regex("#.*$");
        } catch (RegexError e) {
            warning("Failed to compile regex: %s", e.message);
        }
        
        // Set up drawing
        set_draw_func(draw);
        set_size_request(100, -1);
        
        // Set up gesture controllers
        var click_gesture = new Gtk.GestureClick();
        click_gesture.set_button(1); // Left mouse button
        click_gesture.pressed.connect(on_button_press);
        click_gesture.released.connect(on_button_release);
        add_controller(click_gesture);
        
        var drag_gesture = new Gtk.GestureDrag();
        drag_gesture.drag_begin.connect(on_drag_begin);
        drag_gesture.drag_update.connect(on_drag_update);
        drag_gesture.drag_end.connect(on_drag_end);
        add_controller(drag_gesture);
        
        // Motion controller for hover effects
        var motion_controller = new Gtk.EventControllerMotion();
        motion_controller.motion.connect(on_motion);
        motion_controller.leave.connect(on_leave);
        add_controller(motion_controller);
    }
    
    /**
     * Load a new file into the minimap
     */
    public void load_file(string content) {
        file_content = content;
        lines = file_content.split("\n");
        queue_draw();
    }
    
    /**
     * Update the viewport position using pixel ratios
     * @param start_ratio Position ratio (0-1) from top of document
     * @param height_ratio Height ratio (0-1) of viewport relative to document
     */
    public void set_viewport_ratio(double start_ratio, double height_ratio) {
        viewport_start_ratio = double.max(0, double.min(start_ratio, 1.0));
        viewport_height_ratio = double.max(0.01, double.min(height_ratio, 1.0));
        queue_draw();
    }
    
    /**
     * Set callback function for viewport changes
     */
    public void set_viewport_change_callback(ViewportChangeFunc callback) {
        viewport_change_callback = callback;
    }
    
    /**
     * Handle mouse motion for hover effects
     */
    private void on_motion(double x, double y) {
        hover_y = y;
        queue_draw();
    }
    
    /**
     * Handle mouse leaving the widget
     */
    private void on_leave() {
        hover_y = null;
        queue_draw();
    }
    
    /**
     * Handle mouse button press
     */
    private void on_button_press(int n_press, double x, double y) {
        // Cancel any ongoing animation
        cancel_animations();
        
        // Check if click is within viewport area
        int height = get_height();
        double viewport_y = viewport_start_ratio * height;
        double viewport_height = viewport_height_ratio * height;
        
        // If clicking on viewport, prepare for drag operation
        if (y >= viewport_y && y <= viewport_y + viewport_height) {
            dragging_viewport = true;
        } else {
            dragging_viewport = false;
            // Update viewport immediately on click outside viewport
            update_viewport_from_y(y);
        }
    }
    
    /**
     * Handle mouse button release
     */
    private void on_button_release(int n_press, double x, double y) {
        dragging_viewport = false;
    }
    
    /**
     * Handle start of drag operation
     */
    private void on_drag_begin(double start_x, double start_y) {
        dragging = true;
        drag_start_y = start_y;
        drag_start_ratio = viewport_start_ratio;
        
        // Cancel any ongoing animation
        cancel_animations();
        
        // Initialize drag physics
        last_drag_time = get_monotonic_time() / 1000000.0;
        last_drag_y = start_y;
        drag_velocity = 0;
    }
    
    /**
     * Handle mouse drag
     */
    private void on_drag_update(double offset_x, double offset_y) {
        if (!dragging) {
            return;
        }
        
        // Calculate drag physics
        double current_time = get_monotonic_time() / 1000000.0;
        double time_delta = current_time - last_drag_time;
        if (time_delta > 0) {
            double current_y = drag_start_y + offset_y;
            double y_delta = current_y - last_drag_y;
            drag_velocity = y_delta / time_delta;
            last_drag_y = current_y;
            last_drag_time = current_time;
        }
        
        int height = get_height();
        
        if (dragging_viewport) {
            // Drag the viewport directly
            double drag_ratio = offset_y / height;
            double new_ratio = drag_start_ratio + drag_ratio;
            set_viewport_start_ratio(new_ratio);
        } else {
            // Update based on absolute position
            update_viewport_from_y(drag_start_y + offset_y);
        }
    }
    
    /**
     * Handle end of drag operation
     */
    private void on_drag_end(double offset_x, double offset_y) {
        dragging = false;
        dragging_viewport = false;
        
        // Apply momentum scrolling if velocity is significant
        if (Math.fabs(drag_velocity) > 100) { // Threshold for momentum
            // Cap the velocity to prevent too fast scrolling
            double velocity = Math.fmax(Math.fmin(drag_velocity, 2000), -2000);
            momentum_scroll_id = Timeout.add(16, () => {
                return momentum_scroll(velocity);
            });
        }
    }
    
    /**
     * Continue scrolling with momentum
     */
    private bool momentum_scroll(double velocity) {
        // Apply friction to slow down
        velocity *= 0.95;
        
        // Stop when velocity becomes too small
        if (Math.fabs(velocity) < 10) {
            momentum_scroll_id = 0;
            return false;
        }
        
        // Calculate distance to scroll based on velocity
        int height = get_height();
        double ratio_delta = velocity * 0.016 / height;
        
        // Apply the scroll
        double new_ratio = viewport_start_ratio + ratio_delta;
        set_viewport_start_ratio(new_ratio);
        
        return true; // Continue animation
    }
    
    /**
     * Cancel any ongoing animations
     */
    private void cancel_animations() {
        if (animation_source_id > 0) {
            Source.remove(animation_source_id);
            animation_source_id = 0;
        }
        
        if (momentum_scroll_id > 0) {
            Source.remove(momentum_scroll_id);
            momentum_scroll_id = 0;
        }
        
        target_viewport_ratio = null;
    }
    
    /**
     * Update viewport based on mouse y position
     */
    private void update_viewport_from_y(double y) {
        int height = get_height();
        
        if (height > 0) {
            // Convert y position to ratio
            double clicked_ratio = y / height;
            
            // Center the viewport around the clicked position if possible
            double half_height_ratio = viewport_height_ratio / 2;
            double new_ratio = clicked_ratio - half_height_ratio;
            
            set_viewport_start_ratio(new_ratio);
        }
    }
    
    /**
     * Set viewport start ratio with bounds checking
     */
    private void set_viewport_start_ratio(double new_ratio) {
        // Apply bounds
        new_ratio = double.max(0, new_ratio);
        new_ratio = double.min(new_ratio, 1.0 - viewport_height_ratio);
        
        if (new_ratio != viewport_start_ratio) {
            // Set target for smooth animation
            target_viewport_ratio = new_ratio;
            
            // Start animation if not already running
            if (animation_source_id == 0) {
                animation_source_id = Timeout.add(16, animate_viewport);
            }
            
            // Notify about viewport change immediately
            if (viewport_change_callback != null) {
                viewport_change_callback(new_ratio);
            }
        }
    }
    
    /**
     * Animate viewport movement for smooth scrolling
     */
    private bool animate_viewport() {
        if (target_viewport_ratio == null) {
            animation_source_id = 0;
            return false;
        }
        
        // Calculate step size (easing function)
        double diff = target_viewport_ratio - viewport_start_ratio;
        if (Math.fabs(diff) < 0.001) {
            // We're close enough, snap to target
            viewport_start_ratio = target_viewport_ratio;
            target_viewport_ratio = null;
            animation_source_id = 0;
            queue_draw();
            return false;
        }
        
        // Move toward target with easing
        double step = diff * 0.3;
        viewport_start_ratio += step;
        queue_draw();
        return true;
    }
    
    /**
     * Determine color based on line content
     */
    private Gdk.RGBA get_line_color(string line) {
        try {
            if (comment_pattern.match(line)) {
                return comment_color;
            } else if (string_pattern.match(line)) {
                return string_color;
            } else if (keyword_pattern.match(line)) {
                return keyword_color;
            }
        } catch (RegexError e) {
            // Fallback to default text color on error
        }
        return text_color;
    }
    
    /**
     * Draw the minimap
     */
    private void draw(Gtk.DrawingArea da, Cairo.Context cr, int width, int height) {
        // Clear the background
        cr.set_source_rgb(0.95, 0.95, 0.95);
        cr.paint();
        
        if (lines.length == 0) {
            return;
        }
        
        // Calculate dimensions for text representation
        double total_content_height = lines.length * line_height;
        double scale_factor = total_content_height > 0 ? 
                             Math.fmin(1.0, height / total_content_height) : 1.0;
        
        // Draw hover indicator if mouse is over the widget
        if (hover_y != null && !dragging) {
            // Convert hover position to document ratio
            double hover_ratio = hover_y / height;
            
            // Draw hover indicator
            cr.set_source_rgba(0.8, 0.8, 0.9, 0.3);
            cr.rectangle(0, hover_y, width, 2);
            cr.fill();
        }
        
        // Draw the viewport highlight
        double viewport_y = viewport_start_ratio * height;
        double viewport_height = viewport_height_ratio * height;
        
        // Draw the viewport background
        Gdk.cairo_set_source_rgba(cr, highlight_color);
        cr.rectangle(0, viewport_y, width, viewport_height);
        cr.fill();
        
        // Draw a border around the viewport for better visibility
        if (dragging && dragging_viewport) {
            // Use a more prominent color when dragging the viewport
            Gdk.cairo_set_source_rgba(cr, drag_color);
            cr.set_line_width(2);
        } else {
            cr.set_source_rgba(0.5, 0.5, 0.7, 0.8);
            cr.set_line_width(1);
        }
        
        cr.rectangle(0, viewport_y, width, viewport_height);
        cr.stroke();
        
        // Draw a handle indicator on the viewport
        if (hover_y != null && !dragging) {
            double viewport_center_y = viewport_y + viewport_height / 2;
            
            // Only show handle when hovering near the viewport
            if (Math.fabs(hover_y - viewport_center_y) < viewport_height) {
                int handle_width = 4;
                cr.set_source_rgba(0.5, 0.5, 0.8, 0.9);
                cr.rectangle(width - handle_width, viewport_y, handle_width, viewport_height);
                cr.fill();
            }
        }
        
        // Draw the text representation with syntax highlighting
        for (int i = 0; i < lines.length; i++) {
            double y = i * line_height * scale_factor;
            
            // Skip if outside visible area (with some margin)
            if (y > height + 10) {
                break;
            }
            
            if (y < -10) {
                continue;
            }
            
            // Set color based on line content
            Gdk.cairo_set_source_rgba(cr, get_line_color(lines[i]));
            
            // Draw line representation based on content length
            double line_width = double.min(width - padding * 2, lines[i].length * 0.5);
            if (line_width > 0) {
                cr.rectangle(padding, y + padding/2, 
                            line_width, line_height * scale_factor - padding);
                cr.fill();
            }
        }
    }
}
