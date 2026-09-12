import 'package:flutter/widgets.dart';
import 'package:carpenter_units/carpenter_units.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/text.dart';

/// Experimental account-owned messenger shell. The host supplies the workspace,
/// readable account label and logout action; no authentication or routing is owned
/// here. Header actions wrap on phones and with enlarged text.
class CarpenterMessengerHost extends StatelessWidget {
  /// [child] fills the available body. [problem] is safe user-facing copy.
  /// Omit [onLogout] where the session cannot be ended by this surface.
  const CarpenterMessengerHost({
    super.key,
    required this.title,
    required this.accountLabel,
    required this.child,
    this.onLogout,
    this.problem,
  });

  /// User-facing title of this messenger surface.
  final String title;

  /// Account display label; never a credential or redirect URL.
  final String accountLabel;

  /// Account-owned workspace, removed before the session is closed by the host.
  final Widget child;

  /// Optional explicit account exit; the host owns busy/error handling.
  final VoidCallback? onLogout;

  /// Recoverable host error, such as an unreadable selected file.
  final String? problem;
  /// Composes the wrapping header and bounded workspace using theme spacing.
  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    return ColoredBox(
      color: theme.surface.base,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(gap),
            child: Wrap(
              spacing: gap,
              runSpacing: gap / 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CarpenterText.body(title),
                CarpenterText.body(accountLabel),
                if (onLogout != null)
                  CarpenterButton.text(label: 'Выйти', onPressed: onLogout),
              ],
            ),
          ),
          if (problem != null)
            Padding(
              padding: EdgeInsets.all(gap),
              child: Semantics(
                liveRegion: true,
                child: CarpenterText.body(problem!),
              ),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
