#!/usr/bin/env python3
"""Build the Q-SYS .qplug file from framework-style Lua includes."""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
INCLUDE_RE = re.compile(r'--\[\[\s*#include\s+"([^"]+)"\s*\]\]')


def expand_includes(path: Path, seen: list[Path] | None = None) -> str:
    seen = seen or []
    text = path.read_text()

    def replace(match: re.Match[str]) -> str:
        include_path = ROOT / match.group(1)
        if include_path in seen:
            chain = " -> ".join(item.name for item in seen + [include_path])
            raise RuntimeError(f"Circular include detected: {chain}")
        return expand_includes(include_path, seen + [include_path])

    return INCLUDE_RE.sub(replace, text)


def main() -> None:
    output = ROOT / "DCH-ArthurHolm_ERT-30_ALB15HDMR.qplug"
    output.write_text(expand_includes(ROOT / "plugin.lua"))
    print(output)


if __name__ == "__main__":
    main()
