#!/usr/bin/env python3
"""
Check that all imports used in notebooks are available in the environment.

Usage:
    python scripts/check_imports.py [--verbose]

Or via Makefile:
    make test-imports
"""

import json
import re
import sys
import importlib
from pathlib import Path
from collections import defaultdict


def extract_imports_from_code(code: str) -> set[str]:
    """Extract top-level module names from Python code."""
    imports = set()

    # Match: import foo, import foo.bar, import foo as f
    for match in re.finditer(r'^import\s+([\w.]+)', code, re.MULTILINE):
        module = match.group(1).split('.')[0]
        imports.add(module)

    # Match: from foo import bar, from foo.bar import baz
    for match in re.finditer(r'^from\s+([\w.]+)\s+import', code, re.MULTILINE):
        module = match.group(1).split('.')[0]
        imports.add(module)

    return imports


def extract_imports_from_notebook(notebook_path: Path) -> set[str]:
    """Extract all imports from a Jupyter notebook."""
    imports = set()

    try:
        with open(notebook_path) as f:
            nb = json.load(f)

        for cell in nb.get('cells', []):
            if cell.get('cell_type') == 'code':
                source = cell.get('source', [])
                if isinstance(source, list):
                    source = ''.join(source)
                imports.update(extract_imports_from_code(source))
    except (json.JSONDecodeError, KeyError) as e:
        print(f"  Warning: Could not parse {notebook_path}: {e}", file=sys.stderr)

    return imports


def check_import(module_name: str) -> tuple[bool, str]:
    """Try to import a module and return success status and error message."""
    try:
        importlib.import_module(module_name)
        return True, ""
    except ImportError as e:
        return False, str(e)
    except Exception as e:
        return False, f"Unexpected error: {e}"


def main():
    verbose = '--verbose' in sys.argv or '-v' in sys.argv

    # Find all notebooks (exclude _build and checkpoints)
    book_dir = Path(__file__).parent.parent / 'book'
    notebooks = list(book_dir.rglob('*.ipynb'))
    notebooks = [nb for nb in notebooks
                 if '.ipynb_checkpoints' not in str(nb)
                 and '_build' not in str(nb)]

    # Patterns for draft/optional notebooks (not tested in make test-notebooks)
    optional_notebook_patterns = {'Untitled', 'practice_notes'}

    print("=" * 50)
    print("Checking imports in notebooks")
    print("=" * 50)
    print(f"\nScanning {len(notebooks)} notebooks...\n")

    # Extract all imports and track which notebooks use them
    import_sources = defaultdict(list)

    for nb_path in sorted(notebooks):
        imports = extract_imports_from_notebook(nb_path)
        rel_path = nb_path.relative_to(book_dir.parent)
        for imp in imports:
            import_sources[imp].append(str(rel_path))

    # Local modules that are part of this repo (not packages)
    local_modules = {'rl_exp', 'sdt_exp', 'generate_dataset'}

    # Filter out standard library modules that are always available
    stdlib = {
        'os', 'sys', 're', 'json', 'math', 'random', 'time', 'datetime',
        'collections', 'itertools', 'functools', 'pathlib', 'typing',
        'copy', 'string', 'io', 'csv', 'pickle', 'glob', 'shutil',
        'subprocess', 'threading', 'multiprocessing', 'socket', 'urllib',
        'http', 'html', 'xml', 'email', 'logging', 'unittest', 'doctest',
        'pprint', 'textwrap', 'struct', 'codecs', 'unicodedata', 'locale',
        'gettext', 'argparse', 'optparse', 'configparser', 'tempfile',
        'warnings', 'contextlib', 'abc', 'atexit', 'traceback', 'gc',
        'inspect', 'dis', 'zipfile', 'tarfile', 'gzip', 'bz2', 'lzma',
        'hashlib', 'hmac', 'secrets', 'base64', 'binascii', 'quopri',
        'uu', 'difflib', 'operator', 'numbers', 'decimal', 'fractions',
        'statistics', 'cmath', 'array', 'weakref', 'types', 'enum',
        'dataclasses', 'graphlib', 'pdb', 'faulthandler', 'asyncio',
        'concurrent', 'contextvars', 'signal', 'mmap', 'ctypes', 'platform',
        'errno', 'stat', 'fileinput', 'fnmatch', 'linecache', 'netrc',
        'xdrlib', 'plistlib', 'getpass', 'curses', 'readline', 'rlcompleter',
        'builtins', '__future__', 'ast', 'symtable', 'token', 'keyword',
        'tokenize', 'tabnanny', 'pyclbr', 'compileall', 'zipimport',
        'pkgutil', 'modulefinder', 'runpy', 'importlib', 'sqlite3',
    }

    # Check each third-party import (exclude stdlib and local modules)
    third_party = {k: v for k, v in import_sources.items()
                   if k not in stdlib and k not in local_modules}

    # Separate required vs optional imports based on notebook sources
    def is_optional_only(sources: list[str]) -> bool:
        """Check if all sources are optional/draft notebooks."""
        for src in sources:
            is_optional = any(pat in src for pat in optional_notebook_patterns)
            if not is_optional:
                return False
        return True

    print(f"Found {len(third_party)} third-party imports to check:\n")

    passed = []
    failed_required = []
    failed_optional = []

    for module in sorted(third_party.keys()):
        success, error = check_import(module)
        sources = third_party[module]
        optional = is_optional_only(sources)

        if success:
            passed.append(module)
            if verbose:
                print(f"  ✓ {module}")
        else:
            if optional:
                failed_optional.append((module, error, sources))
                if verbose:
                    print(f"  ○ {module} (optional)")
            else:
                failed_required.append((module, error, sources))
                print(f"  ✗ {module}")
                if verbose:
                    print(f"      Error: {error}")
                    print(f"      Used in: {', '.join(sources[:3])}" +
                          (f" (+{len(sources)-3} more)" if len(sources) > 3 else ""))

    # Summary
    print("\n" + "=" * 50)
    required_count = len(third_party) - len(failed_optional)
    print(f"RESULTS: {len(passed)}/{required_count} required imports available")
    if failed_optional:
        print(f"         {len(failed_optional)} optional imports missing (draft notebooks only)")
    print("=" * 50)

    if failed_required:
        print("\nMissing required packages:")
        for module, error, sources in failed_required:
            print(f"  - {module}")
            print(f"      Used in: {sources[0]}" +
                  (f" (+{len(sources)-1} more)" if len(sources) > 1 else ""))
        print("\nTo fix, add missing packages to the Makefile setup target.")
        return 1

    if failed_optional and verbose:
        print("\nMissing optional packages (draft notebooks only):")
        for module, error, sources in failed_optional:
            print(f"  - {module}")
            print(f"      Used in: {sources[0]}" +
                  (f" (+{len(sources)-1} more)" if len(sources) > 1 else ""))

    print("\nAll required imports are available! ✓")
    return 0


if __name__ == '__main__':
    sys.exit(main())
