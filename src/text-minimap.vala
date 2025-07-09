/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * text-minimap.vala
 *
 * A minimap for text
 *
 * José Miguel Fonte
 */

using Gtk;
using Cairo; 

public class TextMinimap : Gtk.DrawingArea {
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
    
    // Current viewport information
    private double viewport_start = 0;
    private int viewport_size = 20;
    
    // Mouse interaction state
    private bool dragging = false;
    private bool dragging_viewport = false;
    private double drag_start_y = 0;
    private double drag_start_viewport = 0;
    private double? hover_y = null;
    private uint animation_source_id = 0;
    private double? target_viewport_start = null;
    
    // Scroll physics
    private double last_drag_time = 0;
    private double last_drag_y = 0;
    private double drag_velocity = 0;
    private uint momentum_scroll_id = 0;
    
    // Regular expressions for syntax highlighting
    private Regex keyword_pattern;
    private Regex string_pattern;
    private Regex comment_pattern;
    
    public delegate void ViewportChangeFunc(int line);
    public ViewportChangeFunc? viewport_change_callback = null;
    
    public TextMinimap() {
        Object();
        
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
        
        try {
            keyword_pattern = new Regex("\\b(def|class|import|from|if|else|elif|for|while|return|try|except|with)\\b");
            string_pattern = new Regex("(\".*?\"|'.*?')");
            comment_pattern = new Regex("#.*$");
        } catch (RegexError e) {
            warning("Failed to compile regex: %s", e.message);
        }
        
        set_draw_func(draw);
        set_size_request(100, -1);
        
        var click_gesture = new Gtk.GestureClick();
        click_gesture.set_button(1);
        click_gesture.pressed.connect(on_button_press);
        click_gesture.released.connect(on_button_release);
        add_controller(click_gesture);
        
        var drag_gesture = new Gtk.GestureDrag();
        drag_gesture.drag_begin.connect(on_drag_begin);
        drag_gesture.drag_update.connect(on_drag_update);
        drag_gesture.drag_end.connect(on_drag_end);
        add_controller(drag_gesture);
        
        var motion_controller = new Gtk.EventControllerMotion();
        motion_controller.motion.connect(on_motion);
        motion_controller.leave.connect(on_leave);
        add_controller(motion_controller);
    }
    
    public void load_file(string content) {
        file_content = content;
        lines = file_content.split("\n");
        queue_draw();
    }
    
    public void set_viewport(int start_line, int visible_lines) {
        viewport_start = start_line;
        viewport_size = visible_lines;
        queue_draw();
    }
    
    public void set_viewport_change_callback(ViewportChangeFunc callback) {
        viewport_change_callback = callback;
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
        
        // Check if click is within viewport area
        int height = get_height();
        double viewport_y = get_line_y(viewport_start, height);
        double viewport_height = double.min(viewport_size * line_height * calculate_scale_factor(height),
                                          height - viewport_y);
        
        // If clicking on viewport, prepare for drag operation
        if (y >= viewport_y && y <= viewport_y + viewport_height) {
            dragging_viewport = true;
        } else {
            dragging_viewport = false;
            update_viewport_from_y(y);
        }
    }
    
    private void on_button_release(int n_press, double x, double y) {
        dragging_viewport = false;
    }
    
    private void on_drag_begin(double start_x, double start_y) {
        dragging = true;
        drag_start_y = start_y;
        drag_start_viewport = viewport_start;
        
        // Cancel any ongoing animation
        cancel_animations();
        
        // Initialize drag physics
        last_drag_time = get_monotonic_time() / 1000000.0;
        last_drag_y = start_y;
        drag_velocity = 0;
    }
    
    private void on_drag_update(double offset_x, double offset_y) {
        if (!dragging) {
            return;
        }
        
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
        double scale_factor = calculate_scale_factor(height);
        
        if (dragging_viewport) {
            double drag_lines = offset_y / (line_height * scale_factor);
            double new_start = drag_start_viewport + drag_lines;
            set_viewport_start(new_start);
        } else {
            update_viewport_from_y(drag_start_y + offset_y);
        }
    }
    
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
    
    private bool momentum_scroll(double velocity) {
        velocity *= 0.95;
        
        if (Math.fabs(velocity) < 10) {
            momentum_scroll_id = 0;
            return false;
        }
        
        int height = get_height();
        double scale_factor = calculate_scale_factor(height);
        double lines_delta = velocity * 0.016 / (line_height * scale_factor);
        
        double new_start = viewport_start + lines_delta;
        set_viewport_start(new_start);
        
        return true;
    }
    
    private void cancel_animations() {
        if (animation_source_id > 0) {
            Source.remove(animation_source_id);
            animation_source_id = 0;
        }
        
        if (momentum_scroll_id > 0) {
            Source.remove(momentum_scroll_id);
            momentum_scroll_id = 0;
        }
        
        target_viewport_start = null;
    }
    
    private double calculate_scale_factor(int height) {
        double total_height = lines.length * line_height;
        return total_height > 0 ? double.min(1.0, height / total_height) : 1.0;
    }
    
    private void update_viewport_from_y(double y) {
        int height = get_height();
        int total_lines = lines.length;
        
        if (total_lines > 0) {
            double scale_factor = calculate_scale_factor(height);
            int clicked_line = (int)(y / (line_height * scale_factor));
            
            // Center the viewport around the clicked position
            int new_start = int.max(0, clicked_line - viewport_size / 2);
            new_start = int.min(new_start, total_lines - viewport_size);
            new_start = int.max(0, new_start);
            
            set_viewport_start(new_start);
        }
    }
    
    private void set_viewport_start(double new_start) {
        int total_lines = lines.length;
        
        // Apply bounds
        new_start = double.max(0, new_start);
        new_start = double.min(new_start, total_lines - viewport_size);
        new_start = double.max(0, new_start);
        
        if (new_start != viewport_start) {
            // Set target for smooth animation
            target_viewport_start = new_start;
            
            // Start animation if not already running
            if (animation_source_id == 0) {
                animation_source_id = Timeout.add(16, animate_viewport);
            }
            
            // Notify about viewport change immediately
            if (viewport_change_callback != null) {
                viewport_change_callback((int)new_start);
            }
        }
    }
    
    private bool animate_viewport() {
        if (target_viewport_start == null) {
            animation_source_id = 0;
            return false;
        }
        
        // Calculate step size (easing function)
        double diff = target_viewport_start - viewport_start;
        if (Math.fabs(diff) < 0.5) {
            // We're close enough, snap to target
            viewport_start = target_viewport_start;
            target_viewport_start = null;
            animation_source_id = 0;
            queue_draw();
            return false;
        }
        
        // Move toward target with easing
        double step = diff * 0.3;
        viewport_start += step;
        queue_draw();
        return true;
    }
    
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
            warning ("Error: %s", e.message);
        }
        return text_color;
    }
    
    private double get_line_y(double line_number, int height) {
        double scale_factor = calculate_scale_factor(height);
        return line_number * line_height * scale_factor;
    }
    
    private void draw(Gtk.DrawingArea da, Cairo.Context cr, int width, int height) {
        // Clear the background

        //cr.set_source_rgb(0.95, 0.95, 0.95);
        //cr.paint();
        
        if (lines.length == 0) {
            return;
        }
        
        // Calculate dimensions
        double scale_factor = calculate_scale_factor(height);
        
        // Draw hover indicator if mouse is over the widget
        if (hover_y != null && !dragging) {
            int hover_line = (int)(hover_y / (line_height * scale_factor));
            double hover_y_pos = hover_line * line_height * scale_factor;
            
            Gdk.cairo_set_source_rgba(cr, hover_color);
            cr.rectangle(0, hover_y_pos, width, line_height * scale_factor);
            cr.fill();
        }
        
        // Draw the viewport highlight
        double viewport_y = get_line_y(viewport_start, height);
        double viewport_height = double.min(viewport_size * line_height * scale_factor,
                                          height - viewport_y);
        
        // Draw the viewport background
        Gdk.cairo_set_source_rgba(cr, highlight_color);
        cr.rectangle(0, viewport_y, width, viewport_height);
        cr.fill();
        
        
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
            //cr.set_source_rgba(0.5, 0.5, 0.7, 0.8); // JMF
            
            // Draw line representation based on content length
            double line_width = double.min(width - padding * 2, lines[i].length * 0.5);
            if (line_width > 0) {
                cr.rectangle(padding, y + padding/2, 
                            line_width, line_height * scale_factor - padding);
                cr.fill();
            }
        }

        // Moved the viewport here to stau above the drawn lines
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
    }
}

