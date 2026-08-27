import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';

final class CarpenterText extends StatelessWidget {
  const CarpenterText(
    this.data, {
    super.key,
    required this.role,
    this.emphasis = TypographyEmphasis.regular,
    this.colorRole = ContentColorRole.primary,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  });

  const CarpenterText.title(
    this.data, {
    super.key,
    this.emphasis = TypographyEmphasis.regular,
    this.colorRole = ContentColorRole.primary,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : role = TypographyRole.title;

  const CarpenterText.body(
    this.data, {
    super.key,
    this.emphasis = TypographyEmphasis.regular,
    this.colorRole = ContentColorRole.primary,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : role = TypographyRole.body;

  const CarpenterText.label(
    this.data, {
    super.key,
    this.emphasis = TypographyEmphasis.regular,
    this.colorRole = ContentColorRole.primary,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : role = TypographyRole.label;

  const CarpenterText.caption(
    this.data, {
    super.key,
    this.emphasis = TypographyEmphasis.regular,
    this.colorRole = ContentColorRole.primary,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : role = TypographyRole.caption;

  final String data;
  final TypographyRole role;
  final TypographyEmphasis emphasis;
  final ContentColorRole colorRole;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextDirection? textDirection;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    return Text(
      data,
      style: theme.typography
          .resolve(context, role, emphasis)
          .copyWith(color: theme.content.resolve(colorRole)),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textDirection: textDirection,
      semanticsLabel: semanticsLabel,
    );
  }
}
