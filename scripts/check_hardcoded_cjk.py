from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCAN_ROOT = ROOT / "lib" / "features"

# 扫描展示层文件，避免把 l10n/generated/services/docs 一起扫进去造成大量误报
TARGET_GLOBS = [
    "**/presentation/**/*.dart",
]

STRING_PATTERNS = [
    re.compile(r"'([^'\\]|\\.)*[\u4e00-\u9fff]([^'\\]|\\.)*'"),
    re.compile(r'"([^"\\]|\\.)*[\u4e00-\u9fff]([^"\\]|\\.)*"'),
]


def strip_comments(source: str) -> str:
    result: list[str] = []
    i = 0
    in_single = False
    in_double = False
    in_line_comment = False
    in_block_comment = False
    escaped = False

    while i < len(source):
        ch = source[i]
        nxt = source[i + 1] if i + 1 < len(source) else ""

        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
                result.append(ch)
            i += 1
            continue

        if in_block_comment:
            if ch == "*" and nxt == "/":
                in_block_comment = False
                i += 2
            else:
                if ch == "\n":
                    result.append("\n")
                i += 1
            continue

        if not in_single and not in_double:
            if ch == "/" and nxt == "/":
                in_line_comment = True
                i += 2
                continue
            if ch == "/" and nxt == "*":
                in_block_comment = True
                i += 2
                continue

        result.append(ch)

        if escaped:
            escaped = False
        elif ch == "\\":
            escaped = True
        elif ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double

        i += 1

    return "".join(result)


def find_matches(file_path: Path) -> list[tuple[int, str]]:
    raw = file_path.read_text(encoding="utf-8")
    text = strip_comments(raw)
    matches: list[tuple[int, str]] = []

    for line_no, line in enumerate(text.splitlines(), start=1):
        for pattern in STRING_PATTERNS:
            if pattern.search(line):
                matches.append((line_no, line.strip()))
                break

    return matches


def iter_target_files() -> list[Path]:
    files: set[Path] = set()
    for pattern in TARGET_GLOBS:
        files.update(SCAN_ROOT.glob(pattern))
    return sorted(path for path in files if path.is_file())


def main() -> int:
    findings: list[tuple[Path, int, str]] = []
    for file_path in iter_target_files():
        for line_no, snippet in find_matches(file_path):
            findings.append((file_path.relative_to(ROOT), line_no, snippet))

    if not findings:
        print("No hardcoded Chinese UI string literals found in presentation layer.")
        return 0

    print("Found hardcoded Chinese UI string literals:\n")
    for rel_path, line_no, snippet in findings:
        print(f"{rel_path}:{line_no}: {snippet}")

    print(
        "\nFailing because user-visible Chinese string literals remain in presentation code. "
        "Move them into ARB files and access via context.l10n."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
