from pathlib import Path
import re

ROOTS = [Path('lib'), Path('widgetbook/lib'), Path('example/lib')]
UNITS_IMPORT = "import 'package:carpenter_units/carpenter_units.dart';"


def fmt(value: float) -> str:
    text = f'{value:.6f}'.rstrip('0').rstrip('.')
    if text.startswith('0.'):
        text = text[1:]
    elif text.startswith('-0.'):
        text = '-' + text[2:]
    return text


def ensure_units_import(text: str) -> str:
    if UNITS_IMPORT in text:
        return text
    lines = text.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import '") or line.startswith('import "'):
            insert_at = i + 1
    lines.insert(insert_at, UNITS_IMPORT)
    return '\n'.join(lines) + ('\n' if text.endswith('\n') else '')


changed = []

# Repair the EdgeInsets bug from the original codemod: its NUMBER pass converted
# the freshly-generated rem literal a second time (for example 24px -> 1.5rem -> .09375rem).
for root in ROOTS:
    for path in root.rglob('*.dart'):
        text = path.read_text(encoding='utf-8')
        new = (
            text.replace(
                'context.units(context.units(.09375.rem).rem)',
                'context.units(1.5.rem)',
            )
            .replace(
                'context.units(context.units(.078125.rem).rem)',
                'context.units(1.25.rem)',
            )
            .replace(
                'context.units(context.units(1.09375.rem).rem)',
                'context.units(17.5.rem)',
            )
        )

        # CarpenterAvatar.size is LengthUnit now. Fix every remaining same-line
        # numeric avatar size, including example code that Pages does not build.
        def avatar_size(match: re.Match[str]) -> str:
            px = float(match.group(2))
            return f"{match.group(1)}Rem({fmt(px / 16.0)})"

        new, avatar_count = re.subn(
            r'(CarpenterAvatar\([^\n]*?\bsize:\s*)(\d+(?:\.\d+)?)\b',
            avatar_size,
            new,
        )
        if avatar_count:
            new = ensure_units_import(new)

        if new != text:
            path.write_text(new, encoding='utf-8')
            changed.append(str(path))


def replace(path_str: str, replacements: list[tuple[str, str]]) -> None:
    path = Path(path_str)
    text = path.read_text(encoding='utf-8')
    new = text
    for old, replacement in replacements:
        if old in new:
            new = new.replace(old, replacement)
        elif replacement in new:
            continue
        else:
            raise RuntimeError(
                f'Neither source nor repaired text found in {path}: {old!r}',
            )
    if new != text:
        path.write_text(new, encoding='utf-8')
        if str(path) not in changed:
            changed.append(str(path))


replace(
    'widgetbook/lib/use_cases/basic/migrated_primitives.dart',
    [
        ("label: 'Appearance · Size',\n    initialValue: 40,\n    min: 20,\n    max: 128,", "label: 'Appearance · Size (rem)',\n    initialValue: 2.5,\n    min: 1.25,\n    max: 8,"),
        ('      size: size,', '      size: size.rem,'),
    ],
)

replace(
    'widgetbook/lib/use_cases/behaviour/loading_boundary.dart',
    [
        ('height: context.units(.1875.rem)', 'height: const Rem(.1875)'),
    ],
)

replace(
    'widgetbook/lib/use_cases/collections/migrated_collections.dart',
    [
        ("label: 'Layout · Width',\n    initialValue: 680,\n    min: 320,\n    max: 1000,", "label: 'Layout · Width (rem)',\n    initialValue: 42.5,\n    min: 20,\n    max: 62.5,"),
        ('    width: width,\n  );\n}\n\nfinal class _LifecyclePreview', '    width: width.rem,\n  );\n}\n\nfinal class _LifecyclePreview'),
        ('  final double width;\n\n  @override\n  State<_LifecyclePreview>', '  final LengthUnit width;\n\n  @override\n  State<_LifecyclePreview>'),
        ('    width: widget.width,\n    height: context.units(32.5.rem),', '    width: context.units(widget.width),\n    height: context.units(32.5.rem),'),
        ("label: 'Layout · Width',\n    initialValue: 600,\n    min: 240,\n    max: 900,", "label: 'Layout · Width (rem)',\n    initialValue: 37.5,\n    min: 15,\n    max: 56.25,"),
        ('      width: width,\n      child: CarpenterListTile(', '      width: context.units(width.rem),\n      child: CarpenterListTile('),
    ],
)

replace(
    'widgetbook/lib/use_cases/behaviour/migrated_behaviour.dart',
    [
        ("label: 'Layout · Host width',\n    initialValue: 900,\n    min: 300,\n    max: 1200,", "label: 'Layout · Host width (rem)',\n    initialValue: 56.25,\n    min: 18.75,\n    max: 75,"),
        ('return _SurfacePreview(kind: kind, title: title, body: body, width: width);', 'return _SurfacePreview(\n    kind: kind,\n    title: title,\n    body: body,\n    width: width.rem,\n  );'),
        ('  final double width;\n\n  @override\n  State<_SurfacePreview>', '  final LengthUnit width;\n\n  @override\n  State<_SurfacePreview>'),
        ('    width: widget.width,\n    height: context.units(30.rem),', '    width: context.units(widget.width),\n    height: context.units(30.rem),'),
    ],
)

print(f'Repaired {len(changed)} files')
for path in sorted(changed):
    print(path)
