"""Run with the Windows Python: which modules the plugins import are missing from the frozen Explorer
(PYZ, base_library.zip, extension files).  Usage: bundle_mods.py EXE INTERNAL_DIR MODULE_LIST
"""
import sys, zipfile, pathlib
from PyInstaller.archive.readers import CArchiveReader
exe, internal, wanted = sys.argv[1], pathlib.Path(sys.argv[2]), open(sys.argv[3]).read().split()
archive = CArchiveReader(exe)
pyz = archive.open_embedded_archive(next(n for n in archive.toc if n.endswith('.pyz')))
names = set(pyz.toc)
base = internal / 'base_library.zip'
if base.exists():
    names |= {n[:-4].replace('/', '.').removesuffix('.__init__') for n in zipfile.ZipFile(base).namelist() if n.endswith('.pyc')}
files = {p.name.split('.')[0] for p in internal.glob('*.pyd')} | {p.relative_to(internal).with_suffix('').as_posix().replace('/', '.').split('.cp')[0] for p in internal.rglob('*.pyd')}
missing = []
for mod in wanted:
    parts = mod.split('.')
    found = any('.'.join(parts[:i]) in names or '.'.join(parts[:i]) in files for i in range(len(parts), 0, -1))
    if not found:
        missing.append(mod)
print('missing from the bundle:', missing)
