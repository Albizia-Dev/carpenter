import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:carpenter_units/carpenter_units.dart';
import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/icon.dart';
import '../../../basic/input/input.dart';
import '../../../basic/progress.dart';
import '../../../basic/text.dart';

/// Presentation stages; authentication, persistence and navigation belong to host.
enum CarpenterAccessStage {
  /// Editable identifier/password form.
  credentials,

  /// Form remains visible but cannot submit twice.
  submitting,

  /// Initial connection or session restoration without an editable form.
  connecting,

  /// Waiting for account preparation; an explicit retry may be offered.
  waiting,

  /// User completes an owned authorization flow in another application.
  external,

  /// Service is not enabled for use yet.
  unavailable,

  /// Recoverable error without exposing provider responses.
  failure,

  /// Exit is being completed; no cancellation is implied.
  signingOut,
}

/// Experimental controlled messenger entry pattern, with one primary action and a calm,
/// centered form. Fits a narrow phone, keyboard insets and enlarged text by
/// scrolling. The host owns controllers, password visibility, safe copy and all
/// callbacks. This widget never retains credentials or initiates network work.
class CarpenterMessengerAccess extends StatelessWidget {
  /// Supply caller-owned controllers even for status stages; they are never
  /// disposed here. An empty primary label omits the action; a null callback
  /// keeps it disabled without changing form geometry. Enter submits only an editable,
  /// complete form. Password visibility is always explicitly caller-controlled.
  const CarpenterMessengerAccess({
    super.key,
    required this.stage,
    required this.title,
    required this.description,
    required this.identifier,
    required this.password,
    required this.primaryLabel,
    required this.onPrimary,
    this.errorText,
    this.secondaryLabel,
    this.onSecondary,
    this.passwordVisible = false,
    this.onPasswordVisibilityChanged,
  });

  /// Authoritative presentation stage, independent from focus/hover.
  final CarpenterAccessStage stage;

  /// Human-readable heading; do not pass an internal status code.
  final String title;

  /// Safe explanation of the next step, excluding URLs and tokens.
  final String description;

  /// Host-owned identifier; passwords must never be put in this controller.
  final TextEditingController identifier;

  /// Host-owned sensitive value. Clear on submission/account change in the host.
  final TextEditingController password;

  /// Label of the single prominent action.
  final String primaryLabel;

  /// Form submission or stage-specific retry. Null keeps the action disabled.
  final VoidCallback? onPrimary;

  /// Safe, actionable error copy announced through a live region.
  final String? errorText;

  /// Optional exit/recovery action, distinct from the primary action.
  final String? secondaryLabel;

  /// Null omits the secondary action rather than showing a dead control.
  final VoidCallback? onSecondary;

  /// Whether the host currently reveals the password. Defaults to obscured.
  final bool passwordVisible;

  /// Proposes a visibility change; null hides the reveal control.
  final ValueChanged<bool>? onPasswordVisibilityChanged;

  /// Uses theme roles and layout units; all field and action semantics come
  /// from Carpenter. Labels remain visible independently of placeholders.
  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    final form =
        stage == CarpenterAccessStage.credentials ||
        stage == CarpenterAccessStage.submitting;
    final busy =
        stage == CarpenterAccessStage.connecting ||
        stage == CarpenterAccessStage.submitting ||
        stage == CarpenterAccessStage.signingOut;
    final accent = theme.feedback.resolve(FeedbackColorRole.info);
    return ColoredBox(
      color: theme.surface.base,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.all(gap),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - gap * 2).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: context.units(const Rem(25)),
                      ),
                      child: ListenableBuilder(
                        listenable: Listenable.merge([identifier, password]),
                        builder: (context, _) {
                          final canSubmit =
                              !busy &&
                              (!form ||
                                  (identifier.text.trim().isNotEmpty &&
                                      password.text.isNotEmpty));
                          return FocusTraversalGroup(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: ExcludeSemantics(
                                    child: Container(
                                      width: context.units(const Rem(5)),
                                      height: context.units(const Rem(5)),
                                      decoration: BoxDecoration(
                                        color: accent.background,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(gap),
                                        child: const FittedBox(
                                          child: CarpenterIcon.feedback(
                                            GravityIcons.comments,
                                            feedbackRole:
                                                FeedbackColorRole.info,
                                            size: IconSize.xlarge,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: gap * 2),
                                CarpenterText(
                                  title,
                                  role: TypographyRole.display,
                                  emphasis: TypographyEmphasis.strong,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: gap),
                                CarpenterText(
                                  description,
                                  colorRole: ContentColorRole.secondary,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: gap * 2),
                                if (form) ...[
                                  CarpenterInput(
                                    controller: identifier,
                                    label: 'Логин',
                                    placeholder: 'Ваш логин в Okibi',
                                    availability: busy
                                        ? FieldAvailability.disabled
                                        : FieldAvailability.enabled,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) =>
                                        FocusScope.of(context).nextFocus(),
                                  ),
                                  SizedBox(height: gap),
                                  CarpenterInput(
                                    controller: password,
                                    label: 'Пароль',
                                    obscureText: !passwordVisible,
                                    availability: busy
                                        ? FieldAvailability.disabled
                                        : FieldAvailability.enabled,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) {
                                      if (canSubmit) onPrimary?.call();
                                    },
                                    trailingAction:
                                        onPasswordVisibilityChanged == null
                                        ? null
                                        : CarpenterActionDescriptor(
                                            id: 'password-visibility',
                                            label: passwordVisible
                                                ? 'Скрыть пароль'
                                                : 'Показать пароль',
                                            icon: passwordVisible
                                                ? GravityIcons.eyeSlash
                                                : GravityIcons.eye,
                                            onInvoke: busy
                                                ? null
                                                : () =>
                                                      onPasswordVisibilityChanged!(
                                                        !passwordVisible,
                                                      ),
                                          ),
                                  ),
                                  SizedBox(height: gap),
                                ],
                                if (errorText != null) ...[
                                  Semantics(
                                    liveRegion: true,
                                    child: CarpenterText.feedback(
                                      errorText!,
                                      feedbackRole: FeedbackColorRole.danger,
                                    ),
                                  ),
                                  SizedBox(height: gap),
                                ],
                                if (busy) ...[
                                  CarpenterProgress(semanticLabel: title),
                                  SizedBox(height: gap),
                                ],
                                if (primaryLabel.isNotEmpty)
                                  CarpenterButton.filled(
                                    label: primaryLabel,
                                    size: ControlSize.large,
                                    onPressed: canSubmit ? onPrimary : null,
                                  ),
                                if (onSecondary != null &&
                                    secondaryLabel != null) ...[
                                  SizedBox(height: gap),
                                  CarpenterButton.text(
                                    label: secondaryLabel!,
                                    onPressed: busy ? null : onSecondary,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
