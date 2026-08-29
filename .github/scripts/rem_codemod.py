import re
from pathlib import Path

ROOTS = [Path('lib'), Path('widgetbook/lib'), Path('example/lib')]
EXCLUDED = {
    Path('widgetbook/lib/addons/carpenter_addons.dart'),  # viewport profiles are intentionally logical px
    Path('lib/src/components/basic/color_picker.dart'),  # painter metrics need a separate context-aware pass
    Path('lib/src/foundation/tokens/carpenter.mordant.g.dart'),
}

NAMED = re.compile(
    r'\b(width|height|minWidth|maxWidth|minHeight|maxHeight|spacing|runSpacing|gap|radius|fontSize|iconSize)\s*:\s*(-?\d+(?:\.\d+)?)'
)
EDGE = re.compile(r'(EdgeInsets(?:Directional)?\.(?:all|symmetric|only|fromLTRB)\([^\n]*\))')
CIRCULAR = re.compile(r'((?:BorderRadius|Radius)\.circular\()(-?\d+(?:\.\d+)?)(\))')
SIZE_SECOND = re.compile(r'(Size\([^,]+,\s*)(\d+(?:\.\d+)?)(\))')
NUMBER = re.compile(r'(?<![\w.])-?\d+(?:\.\d+)?')


def fmt_rem(px: float) -> str:
    value = px / 16.0
    text = f'{value:.6f}'.rstrip('0').rstrip('.')
    if text.startswith('0.'):
        text = text[1:]
    elif text.startswith('-0.'):
        text = '-' + text[2:]
    return f'context.units({text}.rem)'


def replace_edge(match: re.Match[str]) -> str:
    expr = match.group(1)
    # The codemod may be run repeatedly while a migration branch evolves.
    # Never reinterpret an EdgeInsets expression that already contains an
    # explicit unit, otherwise 24px -> 1.5rem becomes 1.5/16 rem on the next run.
    if 'context.units(' in expr or '.rem' in expr or '.px' in expr:
        return expr
    return NUMBER.sub(lambda m: fmt_rem(float(m.group(0))), expr)


def transform_line(line: str) -> tuple[str, bool]:
    original = line

    def named(match: re.Match[str]) -> str:
        name, raw = match.groups()
        value = float(raw)
        if value == 0:
            return match.group(0)
        return f'{name}: {fmt_rem(value)}'

    line = NAMED.sub(named, line)
    line = EDGE.sub(replace_edge, line)
    line = CIRCULAR.sub(lambda m: f'{m.group(1)}{fmt_rem(float(m.group(2)))}{m.group(3)}', line)
    line = SIZE_SECOND.sub(lambda m: f'{m.group(1)}{fmt_rem(float(m.group(2)))}{m.group(3)}', line)

    changed = line != original
    if changed:
        # Runtime unit resolution makes these constructor expressions non-const.
        line = line.replace('const SizedBox(', 'SizedBox(')
        line = line.replace('const EdgeInsets', 'EdgeInsets')
        line = line.replace('const BoxConstraints(', 'BoxConstraints(')
        line = line.replace('const BorderRadius.', 'BorderRadius.')
        line = line.replace('const Radius.', 'Radius.')
        line = line.replace('const Size(', 'Size(')
    return line, changed


def add_import(text: str) -> str:
    if "package:carpenter_units/carpenter_units.dart" in text:
        return text
    lines = text.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import '") or line.startswith('import "'):
            insert_at = i + 1
    lines.insert(insert_at, "import 'package:carpenter_units/carpenter_units.dart';")
    return '\n'.join(lines) + ('\n' if text.endswith('\n') else '')


changed_files = []
for root in ROOTS:
    for path in sorted(root.rglob('*.dart')):
        if path in EXCLUDED or path.name.endswith('.g.dart'):
            continue
        text = path.read_text(encoding='utf-8')
        lines = text.splitlines(keepends=True)
        out = []
        changed = False
        for line in lines:
            newline, line_changed = transform_line(line)
            out.append(newline)
            changed |= line_changed
        if not changed:
            continue
        new_text = ''.join(out)
        new_text = add_import(new_text)
        path.write_text(new_text, encoding='utf-8')
        changed_files.append(str(path))

# Layout dimensions represented as tokens should also be root-relative.
metrics = Path('lib/src/foundation/tokens/metrics.mordant.part.yaml')
text = metrics.read_text(encoding='utf-8')
new_text = text.replace('switchInset: 2px', 'switchInset: 0.125rem')
if new_text != text:
    metrics.write_text(new_text, encoding='utf-8')
    changed_files.append(str(metrics))

print(f'Changed {len(changed_files)} files')
for path in changed_files:
    print(path)
