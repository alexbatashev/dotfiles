{ lib, pkgs, ... }:
{
  programs.obsidian = {
    enable = true;
    vaults."Obsidian Notes" = {
      target = "Obsidian Notes";
    };

    # These defaults are applied to each configured vault.
    defaultSettings = {
      corePlugins = [
        "backlink"
        "bases"
        "bookmarks"
        "command-palette"
        "daily-notes"
        "editor-status"
        "file-explorer"
        "file-recovery"
        "footnotes"
        "global-search"
        "markdown-importer"
        "note-composer"
        "outgoing-link"
        "outline"
        "page-preview"
        "properties"
        "slides"
        "switcher"
        "tag-pane"
        "templates"
      ];
      cssSnippets = [
        {
          name = "custom-theme";
          text = ''
            body {
            	/* Vars */
            	--bg:                             #202020;
            	--bg-code:                        #252525;
            	--bg-code-inline:                 #353535;
            	--fg:                             #BBBBBB;
            	--faint:                          #8A8A8A;
            	--red:                            #FF5B56;
            	--green:                          #8EA765;
            	--orange:                         #CC7832;
            	--yellow:                         #FFC66D;
            	--purple:                         #A782BB;
            	--blue:                           #458588;
            	--ui-font:                        'San Francisco', 'Fira Sans';
            	--pref-font:                      'JetBrainsMono Nerd Font';
            	--pref-font-size1:                10px;
            	--pref-font-size2:                12px;
            	--pref-font-size3:                16px;
            	--pref-font-size4:                20px;

            	/* Obsidian Properties */
            	--vault-name-color:               var(--orange);
            	--vault-name-font-weight:         bold;
            	--file-line-width:                80%;
            	--text-normal:                    var(--fg);
                --text-faint:                     var(--faint);
                --text-accent:                    var(--green); /* links and... */
                --text-accent-hover:              var(--yellow); /* links and... */
                --interactive-accent:             var(--green);
                --interactive-accent-hover:       var(--yellow);
                --text-on-accent:                 var(--bg);
                --font-default:                   var(--pref-font), monospace;
                --font-monospace-default:         var(--pref-font), monospace;
                --font-interface:                 var(--ui-font), sans-serif;
                --font-text:                      var(--ui-font), sans-serif;
                --font-print:                     var(--ui-font), sans-serif;
                --font-monospace:                 var(--pref-font), monospace;
                --font-mermaid:                   var(--pref-font), monospace;
            	--font-default:                   var(--ui-font), sans-serif;
            	--font-monospace:                 var(--pref-font), monospace;
            	--font-smallest:                  var(--pref-font-size1);
            	--font-smaller:                   var(--pref-font-size2);
            	--font-small:                     var(--pref-font-size3);
              	--font-ui-smaller:                var(--pref-font-size1);
              	--font-ui-small:                  var(--pref-font-size2);
              	--font-ui-medium:                 var(--pref-font-size3);
              	--font-ui-large:                  var(--pref-font-size4);
              	--font-text-size:                 var(--pref-font-size2);
              	--link-decoration:                none;
              	--link-decoration-hover:          none;
              	--link-external-decoration:       none;
              	--link-external-decoration-hover: none;
              	--code-comment:                   var(--faint);
              	--code-white-space:               pre-wrap;
              	--code-size:  			          calc(var(--font-smaller) * .95);
              	--code-background:                var(--bg-code);
              	--code-normal:                    var(--fg);
            	--code-comment:                   var(--faint);
            	--code-function:                  var(--yellow);
            	--code-important:                 var(--red);
            	--code-keyword:                   var(--orange);
            	--code-operator:                  var(--fg);
            	--code-property:                  var(--purple);
            	--code-punctuation:               var(--fg);
            	--code-string:                    var(--green);
            	--code-tag:                       var(--yellow);
            	--code-value:                     var(--blue);
            	--callout-title-color:            var(--fg);
            	--list-spacing:                   .2em;
            }

            .theme-dark {
            	--background-primary:             var(--bg);
                --background-secondary:           var(--bg);
                --titlebar-background:            var(--bg);
                --titlebar-background-focused:    var(--bg);
            }

            /* Set inline-code attributes */
            .cm-s-obsidian span.cm-inline-code, .markdown-preview-view code {
                color:                            var(--purple);
                background-color:                 var(--bg-code-inline);
                padding:                          0 4px;
                border-radius:                    4px;
            }

            /* Reset the color in read mode on code blocks */
            .markdown-preview-view pre code {
            	color:                            var(--fg);
            }

            /* Match page width for edit & read modes */
            .markdown-source-view.mod-cm6.is-readable-line-width .cm-content,
            .markdown-source-view.mod-cm6.is-readable-line-width .cm-line {
            	max-width: 100%;
            }
          '';
        }
      ];
    };
  };

  # nixpkgs does not expose Remotely Save here, so install plugin files directly
  # from upstream release assets during activation.
  home.activation.installObsidianRemotelySave = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        vault_dir="$HOME/Obsidian Notes/.obsidian"
        plugin_dir="$vault_dir/plugins/remotely-save"
        plugins_file="$vault_dir/community-plugins.json"
        release_api="https://api.github.com/repos/remotely-save/remotely-save/releases/latest"

        run install -d "$plugin_dir"

        tmp_dir="$(mktemp -d)"
        release_json="$tmp_dir/release.json"
        run ${pkgs.curl}/bin/curl -fsSL "$release_api" -o "$release_json"

        tag="$(${pkgs.jq}/bin/jq -r '.tag_name' "$release_json")"
        if [ -z "$tag" ] || [ "$tag" = "null" ]; then
          echo "Failed to resolve latest Remotely Save release tag from $release_api" >&2
          exit 1
        fi

        base_url="https://github.com/remotely-save/remotely-save/releases/download/$tag"
        run ${pkgs.curl}/bin/curl -fsSL "$base_url/main.js" -o "$plugin_dir/main.js"
        run ${pkgs.curl}/bin/curl -fsSL "$base_url/manifest.json" -o "$plugin_dir/manifest.json"
        run ${pkgs.curl}/bin/curl -fsSL "$base_url/styles.css" -o "$plugin_dir/styles.css"

        if [ -f "$plugins_file" ]; then
          tmp_plugins="$(mktemp)"
          ${pkgs.jq}/bin/jq '((. // []) + ["remotely-save"] | unique)' "$plugins_file" > "$tmp_plugins"
          run install -m644 "$tmp_plugins" "$plugins_file"
          rm -f "$tmp_plugins"
        else
          cat > "$plugins_file" <<'EOF'
    ["remotely-save"]
    EOF
        fi

        rm -rf "$tmp_dir"
  '';
}
