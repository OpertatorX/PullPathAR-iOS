from pathlib import Path
import sys
import re

ROOT = Path(r"C:\Users\lucbi\PullPathAR-iOS")
sys.path.insert(0, str(ROOT / ".audit-packages"))

from tree_sitter import Language, Parser
import tree_sitter_swift

language = Language(tree_sitter_swift.language())
parser = Parser(language)

swift_files = sorted((ROOT / "PullPathAR").rglob("*.swift")) + sorted((ROOT / "PullPathARTests").rglob("*.swift"))
problems = []
types = {}

def walk(node, path):
    if node.type == "ERROR" or node.is_missing:
        problems.append((path, node.start_point, node.end_point, node.type, node.is_missing))
    for child in node.children:
        walk(child, path)

for path in swift_files:
    source = path.read_bytes()
    tree = parser.parse(source)
    walk(tree.root_node, path)
    text = source.decode("utf-8", errors="ignore")
    for match in re.finditer(r"(?m)^\s*(?:private\s+|fileprivate\s+|internal\s+|public\s+)?(?:final\s+)?(struct|class|enum|actor)\s+([A-Za-z_][A-Za-z0-9_]*)", text):
        name = match.group(2)
        types.setdefault(name, []).append(path)

print(f"SWIFT_FILES={len(swift_files)}")
if problems:
    print("SYNTAX_PROBLEMS:")
    for problem in problems:
        print(problem)
else:
    print("TREE_SITTER_SYNTAX_PASS")

duplicate_types = {name: paths for name, paths in types.items() if len(set(paths)) > 1}
if duplicate_types:
    print("DUPLICATE_TYPE_NAMES:")
    for name, paths in sorted(duplicate_types.items()):
        print(name, [str(p.relative_to(ROOT)) for p in paths])
else:
    print("DUPLICATE_TYPE_SCAN_PASS")

forbidden = re.compile(r"\b(TODO|FIXME|placeholder|demo-only|fake button|mock button)\b", re.IGNORECASE)
forbidden_hits = []
for path in swift_files:
    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
        if forbidden.search(line):
            forbidden_hits.append((str(path.relative_to(ROOT)), line_no, line.strip()))
if forbidden_hits:
    print("FORBIDDEN_MARKERS:")
    for hit in forbidden_hits:
        print(hit)
else:
    print("FORBIDDEN_MARKER_SCAN_PASS")

if problems or duplicate_types or forbidden_hits:
    raise SystemExit(1)
print("STATIC_SWIFT_AUDIT_PASS")
