"""Run with the Windows Python: the frozen archive holds this fork's esibd modules.

Usage: check_bundle.py EXE VERSION [MARKER_IN_ESIBD_CORE ...]
A marker is a name or string constant that only the fork's code has.
"""
import sys

from PyInstaller.archive.readers import CArchiveReader

exe, version, markers = sys.argv[1], sys.argv[2], sys.argv[3:]
archive = CArchiveReader(exe)
pyz = archive.open_embedded_archive(next(name for name in archive.toc if name.endswith('.pyz')))


def names(code, found=None):
    """Names and string constants of a code object and of the code objects it contains."""
    found = set() if found is None else found
    found.update(code.co_names)
    found.update(c for c in code.co_consts if isinstance(c, str))
    for const in code.co_consts:
        if hasattr(const, 'co_names'):
            names(const, found)
    return found


checks = {'esibd.plugins': ['_nearest_time_index', 'public'],
          'esibd.core': ['_save_dock_tab_order', 'SCIENTIFIC_CURSOR_BELOW', 'reconfigure', *markers],
          'esibd.config': [version]}
ok = True
for module, wanted in checks.items():
    found = names(pyz.extract(module))
    for item in wanted:
        print(module, item, item in found)
        ok &= item in found
print('BUNDLE OK' if ok else 'BUNDLE MISMATCH')
sys.exit(0 if ok else 1)
