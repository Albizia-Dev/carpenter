# Recording composer transition fix

The layout/patterns composer retains one Row and one recording-control slot
through capture, locked, paused, preview and idle. Flexible allocation changes;
the GlobalKey no longer moves between different parents during layout. Text
and attachment controls disappear during the session; the composer keeps its
TextEditingController so the host draft and selection survive.

Public API and the canonical Widgetbook Playground remain unchanged: existing
phase controls exercise the corrected transitions. New non-golden tests cover
focused/hovered transitions under LayoutBuilder; pointer and narrow cases pass.

Checks: library/test analysis clean; 585 package non-golden tests; 89 Widgetbook
non-golden tests and clean analysis; Widgetbook/example web release builds pass.
Documentation audit retains the 311 previously reported coverage issues. No
new API symbols were added. Golden, screenshots and manual UI were not used.

This is the second batched Carpenter publication in Messenger+ completion
(maximum authorized: ten). Desktop application builds/runs remain prohibited;
its tests are now authorized independently.
