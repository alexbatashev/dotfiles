{ config, lib, ... }:
let
  cfg = config.programs.aiAgents;

  skillDirs = [ ../agents/skills ] ++ cfg.extraSkillDirs;

  skillsIn =
    dir:
    lib.mapAttrs (name: _: dir + "/${name}") (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir)
    );

  skills = lib.foldl' (acc: dir: acc // skillsIn dir) { } skillDirs;

  linkSkills =
    prefix: lib.mapAttrs' (name: src: lib.nameValuePair "${prefix}/${name}" { source = src; }) skills;
in
{
  options.programs.aiAgents = {
    instructions = lib.mkOption {
      type = lib.types.path;
      default = ../agents/AGENTS.md;
      description = "Shared agent instructions, linked as CLAUDE.md for Claude Code and AGENTS.md elsewhere.";
    };

    extraSkillDirs = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      example = lib.literalExpression "[ ../agents/skills-work ]";
      description = ''
        Extra directories holding machine-local skills. Each immediate subdirectory
        is linked individually, so a later directory can also shadow a shared skill
        of the same name.
      '';
    };
  };

  config = {
    home.file =
      {
        ".claude/CLAUDE.md".source = cfg.instructions;
        ".codex/AGENTS.md".source = cfg.instructions;
      }
      // linkSkills ".claude/skills"
      // linkSkills ".codex/skills";

    xdg.configFile = {
      "opencode/AGENTS.md".source = cfg.instructions;
    } // linkSkills "opencode/skills";
  };
}
