#!/usr/bin/env python3
"""Read skill files and report size, local links, and optional upstream differences.

Requires PyYAML. Counts whitespace-delimited words, not model tokens.
Relative links are checked as files. Markdown anchors are not validated.
Inline paths are candidates for review because examples can name nonexistent files.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
from urllib.parse import unquote

import yaml


def read_skill(path):
    text = path.read_text()
    match = re.match(r"\A---\n(.*?)\n---(?:\n|$)", text, re.S)
    if not match:
        raise ValueError(f"Missing YAML frontmatter: {path}")
    metadata = yaml.safe_load(match[1])
    if not isinstance(metadata, dict):
        raise ValueError(f"Frontmatter is not a mapping: {path}")
    for field in ("name", "description"):
        if not isinstance(metadata.get(field), str) or not metadata[field].strip():
            raise ValueError(f"Missing string {field}: {path}")
    body = text[match.end():]
    return text, metadata, body


def prose_lines(text):
    fenced = False
    for number, line in enumerate(text.splitlines(), 1):
        if re.match(r"\s*(`{3,}|~{3,})", line):
            fenced = not fenced
            continue
        if not fenced:
            yield number, re.sub(r"`[^`]*`", "", line)


def inventory(root):
    rows = []
    for path in sorted(root.glob("*/SKILL.md")):
        text, metadata, body = read_skill(path)
        lines = list(prose_lines(body))
        rows.append({
            "skill": path.parent.name,
            "name": metadata["name"],
            "sha256": hashlib.sha256(text.encode()).hexdigest(),
            "words": len(text.split()),
            "body_words": len(body.split()),
            "description_characters": len(metadata["description"]),
            "description_words": len(metadata["description"].split()),
            "claude_disable_model_invocation": metadata.get("disable-model-invocation", False),
            "has_codex_openai_yaml": (path.parent / "agents/openai.yaml").is_file(),
            "body_prose_em_dashes": sum(line.count("\u2014") for _, line in lines),
            "body_prose_semicolons": sum(line.count(";") for _, line in lines),
            "support_files": len([p for p in path.parent.rglob("*") if p.is_file() and p != path]),
        })
    if not rows:
        raise ValueError(f"No skills found: {root}")
    return rows


def missing_links(root):
    missing = []
    candidates = []
    for path in sorted(root.rglob("*.md")):
        text = path.read_text()
        for match in re.finditer(r"\[[^\]\n]*\]\(([^)\s]+)\)", text):
            target = unquote(match[1].split("#", 1)[0])
            if not target or re.match(r"(?:[a-z]+:|/|~)", target):
                continue
            if not (path.parent / target).is_file():
                missing.append({"file": str(path.relative_to(root)), "line": text[:match.start()].count("\n") + 1, "target": target})
        for match in re.finditer(r"`([^`\n]+\.(?:md|html|sh))`", text):
            target = match[1]
            if not re.match(r"(?:[a-z]+:|/|~)", target) and not (path.parent / target).is_file():
                candidates.append({"file": str(path.relative_to(root)), "line": text[:match.start()].count("\n") + 1, "target": target})
    return missing, candidates


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1] / "agents/skills")
    parser.add_argument("--upstream", type=Path, help="Path to an already downloaded upstream skills directory")
    parser.add_argument("--upstream-revision", help="Revision label for the supplied upstream directory")
    args = parser.parse_args()
    rows = inventory(args.root)
    missing, candidates = missing_links(args.root)
    totals = {key: sum(row[key] for row in rows) for key in ("words", "body_words", "description_characters", "description_words", "body_prose_em_dashes", "body_prose_semicolons", "support_files")}
    totals.update(skills=len(rows), claude_disabled=sum(row["claude_disable_model_invocation"] is True for row in rows), codex_policy_files=sum(row["has_codex_openai_yaml"] for row in rows))
    report = {"measurement": "Whitespace-delimited words and Unicode characters. Not token usage or behavioral validation.", "totals": totals, "skills": rows, "missing_markdown_link_targets": missing, "unresolved_inline_path_candidates": candidates}
    if args.upstream:
        upstream = {row["skill"]: row for row in inventory(args.upstream)}
        local = {row["skill"]: row for row in rows}
        shared = sorted(local.keys() & upstream.keys())
        comparison = []
        for name in shared:
            comparison.append({"skill": name, "identical": local[name]["sha256"] == upstream[name]["sha256"], "local_words": local[name]["words"], "upstream_words": upstream[name]["words"]})
        report["upstream"] = {"revision": args.upstream_revision, "skills": len(upstream), "shared": comparison, "local_only": sorted(local.keys() - upstream.keys()), "upstream_only": sorted(upstream.keys() - local.keys()), "shared_local_words": sum(local[name]["words"] for name in shared), "shared_upstream_words": sum(upstream[name]["words"] for name in shared)}
    print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
