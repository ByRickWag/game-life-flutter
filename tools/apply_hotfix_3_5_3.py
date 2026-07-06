#!/usr/bin/env python3
from pathlib import Path

root = Path.cwd()
files = list(root.rglob('v2_evolution_pages.dart'))
if not files:
    raise SystemExit('Nenhum v2_evolution_pages.dart encontrado. Rode este script na raiz do projeto Flutter.')

changed = []
for path in files:
    text = path.read_text(encoding='utf-8')
    original = text

    text = text.replace('habits: null,', 'habits: 0,')

    # Garante habits: 0 dentro de blocos const SystemStats vazios que ainda não tenham habits.
    marker = 'const SystemStats('
    index = 0
    while True:
        start = text.find(marker, index)
        if start == -1:
            break
        end = text.find('),', start)
        if end == -1:
            break
        block = text[start:end]
        if 'missions: 0,' in block and 'objectives: 0,' in block and 'habits:' not in block:
            block_fixed = block.replace('objectives: 0,', 'objectives: 0,\n        habits: 0,')
            text = text[:start] + block_fixed + text[end:]
            index = start + len(block_fixed)
        else:
            index = end + 2

    if text != original:
        path.write_text(text, encoding='utf-8')
        changed.append(str(path.relative_to(root)))

print('Arquivos corrigidos:')
for item in changed:
    print(f'- {item}')
if not changed:
    print('- Nenhum arquivo precisava de alteração.')
