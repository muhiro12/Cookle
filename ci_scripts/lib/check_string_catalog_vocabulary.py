#!/usr/bin/env python3
"""Check tracked string catalogs against Cookle's product vocabulary.

Canonical terms are documented in
Designs/Overviews/cookle-product-vocabulary.md. This check keeps the two
mechanical parts of that audit from drifting: stale catalog entries and
superseded translations of the core recipe fields.
"""

import json
import subprocess
import sys

# Superseded translations and their canonical replacements, per locale.
SUPERSEDED_TERMS = {
    "ja": {
        "カテゴリー": "カテゴリ",
        "サービングサイズ": "人数",
        "サービング": "人分",
        "ノート": "メモ",
    },
    "zh-Hans": {
        "类别": "分类",
        "成分": "食材",
        "注释": "备注",
        "份量大小": "份数",
    },
    "es": {
        "Configuraciones": "Ajustes",
        "Tamaño de la porción": "Porciones",
    },
    "fr": {
        "Paramètres": "Réglages",
        "Taille de portion": "Portions",
    },
}


def tracked_catalogs():
    result = subprocess.run(
        ["git", "ls-files", "*.xcstrings"],
        check=True,
        capture_output=True,
        text=True,
    )
    return [path for path in result.stdout.splitlines() if path]


def localized_values(node):
    """Yields every translated value, including plural and device variations."""
    if isinstance(node, dict):
        string_unit = node.get("stringUnit")
        if isinstance(string_unit, dict) and "value" in string_unit:
            yield string_unit["value"]
        for child in node.values():
            if child is not string_unit:
                yield from localized_values(child)


def check_catalog(path):
    errors = []
    with open(path, encoding="utf-8") as file:
        strings = json.load(file)["strings"]

    for key, entry in strings.items():
        if entry.get("extractionState") == "stale":
            errors.append(
                f"{path}: stale key {key!r}. Remove it once no source "
                "references it."
            )
        localizations = entry.get("localizations", {})
        for language, terms in SUPERSEDED_TERMS.items():
            for value in localized_values(localizations.get(language, {})):
                for term, replacement in terms.items():
                    if term in value:
                        errors.append(
                            f"{path}: {key!r} [{language}] uses {term!r}; "
                            f"use {replacement!r}."
                        )
    return errors


def main():
    errors = []
    for path in tracked_catalogs():
        errors.extend(check_catalog(path))

    if errors:
        print("String catalog vocabulary check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
