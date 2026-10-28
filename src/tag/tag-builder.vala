/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * tag-builder.vala
 *
 * Class containing a Tag Builder
 *
 * José Miguel Fonte
 */

namespace Tags {

    public class TagBuilder {
        public ColorScheme  colors;
        public bool         enabled             = true;
        public string?      pattern             = null;
        public string?      description         = null;
        public bool         is_regex            = false;
        public bool         is_case_sensitive   = false;

        public TagBuilder (ColorScheme colors) {
            this.colors = colors;
        }

        /* FIXME: We should be be able to instantiate a TagBuilder without a pattern */
        public TagBuilder set_pattern (string pattern) requires (pattern != null) {
            this.pattern = pattern;
            return this;
        }

        public TagBuilder set_description (string? description) {
            this.description = description;
            return this;
        }

        public TagBuilder set_enabled (bool enabled) {
            this.enabled = enabled;
            return this;
        }

        public TagBuilder set_is_regex (bool is_regex) {
            this.is_regex = is_regex;
            return this;
        }

        public TagBuilder set_is_case_sensitive (bool is_case_sensitive) {
            this.is_case_sensitive = is_case_sensitive;
            return this;
        }

        public TagBuilder set_colors (ColorScheme colors) {
            this.colors = colors;
            return this;
        }

        public Tag build () {
            return new Tag (this);
        }

    }

}
