#!/usr/bin/env python3
"""Fusionne Localizations/_parts/<groupe>/<langue>.strings en Localizations/<langue>.lproj/Localizable.strings.

Même clé dans deux groupes : acceptée si la valeur est identique, sinon signalée (la première gagne).
Contrôle aussi que les 4 langues ont les mêmes clés et les mêmes spécificateurs de format. Code de sortie 1 s'il y a un problème.
"""
import re, sys, pathlib

root = pathlib.Path(__file__).resolve().parent.parent / "Localizations"
langs = ["en", "fr", "es", "it"]
entry = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;\s*(?:/\*.*\*/)?\s*$')
spec = re.compile(r'%(?:\d+\$)?(?:ll)?[@dlfu]|%%')
problems = []
merged = {l: {} for l in langs}

for part in sorted((root / "_parts").iterdir()):
    if not part.is_dir():
        continue
    for l in langs:
        f = part / f"{l}.strings"
        if not f.exists():
            problems.append(f"manque : {f}")
            continue
        for n, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            s = line.strip()
            if not s or s.startswith("/*") or s.startswith("//"):
                continue
            m = entry.match(line)
            if not m:
                problems.append(f"{f.name}:{n} ligne illisible dans {part.name} : {s[:60]}")
                continue
            k, v = m.groups()
            if k in merged[l] and merged[l][k] != v:
                problems.append(f"conflit [{l}] {k[:50]!r}: {merged[l][k][:40]!r} / {v[:40]!r} ({part.name})")
                continue
            merged[l].setdefault(k, v)

def kind(s):
    # types de spécificateurs sans position, triés (l'ordre peut changer d'une langue à l'autre)
    return sorted(re.sub(r'\d+\$', '', x) for x in spec.findall(s))

keys = set(merged["en"])
for l in langs:
    for missing in sorted(keys - set(merged[l])):
        problems.append(f"[{l}] clé absente : {missing[:70]!r}")
    for extra in sorted(set(merged[l]) - keys):
        problems.append(f"[{l}] clé en trop : {extra[:70]!r}")
for k in keys:
    ref = kind(k)
    for l in langs:
        if k in merged[l] and kind(merged[l][k]) != ref:
            problems.append(f"[{l}] formats différents pour {k[:60]!r} : {kind(merged[l][k])} au lieu de {ref}")

for l in langs:
    d = root / f"{l}.lproj"
    d.mkdir(exist_ok=True)
    body = "/* Généré par scripts/merge-localizations.py : ne pas modifier, éditer _parts. */\n"
    body += "".join(f'"{k}" = "{merged[l][k]}";\n' for k in sorted(merged[l]))
    (d / "Localizable.strings").write_text(body, encoding="utf-8")

print(f"{len(keys)} clés × {len(langs)} langues")
for p in problems:
    print("!", p)
sys.exit(1 if problems else 0)
