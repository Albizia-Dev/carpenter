import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';

enum CarpenterTableTypographyRole { header, cell }

/// Text primitive that resolves typography from table component tokens rather
/// than generic label/body roles.
final class CarpenterTableText extends StatelessWidget {
  const CarpenterTableText(
    this.data, {
    super.key,
    this.role = CarpenterTableTypographyRole.cell,
    this.emphasis = TypographyEmphasis.regular,
    this.colorRole = ContentColorRole.primary,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  });

  const CarpenterTableText.header(
    this.data, {
    super.key,
    this.emphasis = TypographyEmphasis.strong,
    this.colorRole = ContentColorRole.primary,
    this.textAlign,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap,
    this.semanticsLabel,
  }) : role = CarpenterTableTypographyRole.header;

  const CarpenterTableText.cell(
    this.data, {
    super.key,
    this.emphasis = TypographyEmphasis.regular,
    this.colorRole = ContentColorRole.primary,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : role = CarpenterTableTypographyRole.cell;

  final String data;
  final CarpenterTableTypographyRole role;
  final TypographyEmphasis emphasis;
  final ContentColorRole colorRole;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final style = switch (role) {
      CarpenterTableTypographyRole.header =>
        theme.typography.tableHeader(context, emphasis),
      CarpenterTableTypographyRole.cell =>
        theme.typography.tableCell(context, emphasis),
    };
    return Text(
      data,
      style: style.copyWith(color: theme.content.resolve(colorRole)),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
    );
  }
}
