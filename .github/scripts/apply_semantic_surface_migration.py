from pathlib import Path

path = Path('lib/src/components/basic/input/file_input.dart')
text = path.read_text()

old = '''        builder: (context, state) {
          final theme = CarpenterTheme.of(context);
          final role = !state.hovering
              ? FeedbackColorRole.neutral
              : state.accepts
              ? FeedbackColorRole.success
              : FeedbackColorRole.danger;
          final colors = theme.feedback.resolve(role);
          return CarpenterCard(
            semanticLabel: semanticLabel,
            borderColor: state.hovering ? colors.foreground : null,
            backgroundColor: state.hovering ? colors.background : null,
            child: SizedBox(
              height: context.units(7.rem),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CarpenterIcon(
                    CarpenterIcons.upload,
                    colorRole: state.hovering && state.accepts
                        ? ContentColorRole.primary
                        : ContentColorRole.secondary,
                  ),
                  SizedBox(height: context.units(.5.rem)),
                  CarpenterText.label(
                    title,
                    emphasis: TypographyEmphasis.strong,
                    textAlign: TextAlign.center,
                  ),
                  CarpenterText.caption(
                    state.hovering
                        ? state.accepts
                              ? 'Release to add files'
                              : 'These files are not accepted'
                        : description,
                    colorRole: ContentColorRole.secondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
'''

new = '''        builder: (context, state) {
          final role = state.accepts
              ? FeedbackColorRole.success
              : FeedbackColorRole.danger;
          final content = SizedBox(
            height: context.units(7.rem),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.hovering)
                  CarpenterIcon.feedback(
                    CarpenterIcons.upload,
                    feedbackRole: role,
                  )
                else
                  const CarpenterIcon(
                    CarpenterIcons.upload,
                    colorRole: ContentColorRole.secondary,
                  ),
                SizedBox(height: context.units(.5.rem)),
                if (state.hovering)
                  CarpenterText.feedback(
                    title,
                    feedbackRole: role,
                    role: TypographyRole.label,
                    emphasis: TypographyEmphasis.strong,
                    textAlign: TextAlign.center,
                  )
                else
                  CarpenterText.label(
                    title,
                    emphasis: TypographyEmphasis.strong,
                    textAlign: TextAlign.center,
                  ),
                if (state.hovering)
                  CarpenterText.feedback(
                    state.accepts
                        ? 'Release to add files'
                        : 'These files are not accepted',
                    feedbackRole: role,
                    role: TypographyRole.caption,
                    textAlign: TextAlign.center,
                  )
                else
                  CarpenterText.caption(
                    description,
                    colorRole: ContentColorRole.secondary,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          );
          if (state.hovering) {
            return CarpenterCard.feedback(
              semanticLabel: semanticLabel,
              role: role,
              child: content,
            );
          }
          return CarpenterCard(semanticLabel: semanticLabel, child: content);
        },
'''

count = text.count(old)
if count != 1:
    raise SystemExit(f'expected exactly one FileDropZone surface block, got {count}')
path.write_text(text.replace(old, new))
