"""Standard-library and other modules the plugins import (one per line), for bundle_mods.py.

Usage: plugin_imports.py PLUGINS_REPOSITORY
"""
import ast
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
modules = set()
for path in root.glob('*/**/*.py'):
    relative = path.relative_to(root)
    if relative.parts[0] in ('tests', 'tools', 'notebooks', 'native', 'docs') or relative.parts[0].startswith('.') \
            or '__pycache__' in relative.parts:
        continue
    for node in ast.walk(ast.parse(path.read_text(encoding='utf-8'))):
        if isinstance(node, ast.Import):
            modules.update(alias.name for alias in node.names)
        elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            modules.add(node.module)
print('\n'.join(sorted(modules)))
