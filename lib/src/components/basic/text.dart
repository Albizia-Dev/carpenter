import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';

final class CarpenterText extends StatelessWidget {
  const CarpenterText(
    this.data, {
    super.key,
    this.role = .body,
    this.emphasis = TypographyEmphasis.regular,
    this.colorRole = ContentColorRole.primary,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : feedbackRole = null;

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
  }) : role = TypographyRole.title,
       feedbackRole = null;

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
  }) : role = TypographyRole.body,
       feedbackRole = null;

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
  }) : role = TypographyRole.label,
       feedbackRole = null;

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
  }) : role = TypographyRole.caption,
       feedbackRole = null;

  const CarpenterText.feedback(
    this.data, {
    super.key,
    required this.feedbackRole,
    this.role = TypographyRole.body,
    this.emphasis = TypographyEmphasis.regular,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textDirection,
    this.semanticsLabel,
  }) : colorRole = ContentColorRole.primary;

  final String data;
  final TypographyRole role;
  final TypographyEmphasis emphasis;
  final ContentColorRole colorRole;
  final FeedbackColorRole? feedbackRole;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextDirection? textDirection;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final style = theme.typography.resolve(context, role, emphasis);
    final color = feedbackRole == null
        ? theme.content.resolve(colorRole)
        : theme.feedback.resolve(feedbackRole!).foreground;
    return Text(
      data,
      style: style.copyWith(color: color),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textDirection: textDirection,
      semanticsLabel: semanticsLabel,
    );
  }
}
