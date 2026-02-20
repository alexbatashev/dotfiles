{ ... }:
{
  programs.helix = {
    enable         = true;
    defaultEditor  = true;

    settings = {
      theme = "dark_plus";

      keys.normal = {
        "{"  = [ "goto_prev_paragraph"  "collapse_selection" ];
        "}"  = [ "goto_next_paragraph"  "collapse_selection" ];
        "0"  = "goto_line_start";
        "$"  = "goto_line_end";
        "^"  = "goto_first_nonwhitespace";
        "G"  = "goto_file_end";
        "%"  = "match_brackets";
        "V"  = [ "select_mode" "extend_to_line_bounds" ];
        "C"  = [ "extend_to_line_end" "yank_main_selection_to_clipboard" "delete_selection" "insert_mode" ];
        "D"  = [ "extend_to_line_end" "yank_main_selection_to_clipboard" "delete_selection" ];
        "S"  = "surround_add";
        "x"  = "delete_selection";
        "p"  = [ "paste_clipboard_after"  "collapse_selection" ];
        "P"  = [ "paste_clipboard_before" "collapse_selection" ];
        "Y"  = [ "extend_to_line_end" "yank_main_selection_to_clipboard" "collapse_selection" ];
        "u"  = [ "undo" "collapse_selection" ];
        "esc" = [ "collapse_selection" "keep_primary_selection" ];
        "j"  = "move_line_down";
        "k"  = "move_line_up";
        "*"  = [ "move_char_right" "move_prev_word_start" "move_next_word_end" "search_selection" "search_next" ];
        "#"  = [ "move_char_right" "move_prev_word_start" "move_next_word_end" "search_selection" "search_prev" ];
        ";"  = "command_mode";

        d.d = [ "extend_to_line_bounds" "yank_main_selection_to_clipboard" "delete_selection" ];
        y.y = [ "extend_to_line_bounds" "yank_main_selection_to_clipboard" "normal_mode" "collapse_selection" ];
      };

      keys.insert = {
        "esc" = [ "collapse_selection" "normal_mode" ];
      };

      keys.select = {
        "{"  = [ "extend_to_line_bounds" "goto_prev_paragraph" ];
        "}"  = [ "extend_to_line_bounds" "goto_next_paragraph" ];
        "0"  = "goto_line_start";
        "$"  = "goto_line_end";
        "^"  = "goto_first_nonwhitespace";
        "G"  = "goto_file_end";
        "D"  = [ "extend_to_line_bounds" "delete_selection" "normal_mode" ];
        "C"  = [ "goto_line_start" "extend_to_line_bounds" "change_selection" ];
        "%"  = "match_brackets";
        "S"  = "surround_add";
        "u"  = [ "switch_to_lowercase" "collapse_selection" "normal_mode" ];
        "U"  = [ "switch_to_uppercase" "collapse_selection" "normal_mode" ];
        "k"  = [ "extend_line_up"   "extend_to_line_bounds" ];
        "j"  = [ "extend_line_down" "extend_to_line_bounds" ];
        "d"  = [ "yank_main_selection_to_clipboard" "delete_selection" ];
        "x"  = [ "yank_main_selection_to_clipboard" "delete_selection" ];
        "y"  = [ "yank_main_selection_to_clipboard" "normal_mode" "flip_selections" "collapse_selection" ];
        "Y"  = [ "extend_to_line_bounds" "yank_main_selection_to_clipboard" "goto_line_start" "collapse_selection" "normal_mode" ];
        "p"  = "replace_selections_with_clipboard";
        "P"  = "paste_clipboard_before";
        "esc" = [ "collapse_selection" "keep_primary_selection" "normal_mode" ];
      };
    };
  };
}
