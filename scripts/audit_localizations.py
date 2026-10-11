from pathlib import Path
import re

ROOT = Path(r"C:\Users\lucbi\PullPathAR-iOS\PullPathAR")
PREFIXES = (
    "tab.", "common.", "projects.", "routes.", "route.", "reels.", "reel.",
    "profiles.", "cable.category.", "photos.", "history.", "settings.", "units.",
    "manual.", "capture."
)
used = set()
for path in ROOT.rglob("*.swift"):
    text = path.read_text(encoding="utf-8", errors="ignore")
    for value in re.findall(r'"([^"\n]+)"', text):
        if value.startswith(PREFIXES):
            used.add(value)

def locale_keys(path: Path):
    text = path.read_text(encoding="utf-8")
    return set(re.findall(r'^\s*"([^"]+)"\s*=', text, flags=re.M))

en = locale_keys(ROOT / "Resources/en.lproj/Localizable.strings")
fr = locale_keys(ROOT / "Resources/fr.lproj/Localizable.strings")
missing_en = sorted(used - en)
missing_fr = sorted(used - fr)
extra_mismatch = sorted((en ^ fr))
print("USED", len(used))
print("EN", len(en), "FR", len(fr))
print("MISSING_EN", missing_en)
print("MISSING_FR", missing_fr)
print("EN_FR_KEY_MISMATCH", extra_mismatch)
if missing_en or missing_fr or extra_mismatch:
    raise SystemExit(1)
print("LOCALIZATION_AUDIT_PASS")
