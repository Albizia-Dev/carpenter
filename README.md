# Carpenter

## Status

Carpenter is in early experimental development. The public API is intentionally
incomplete and unstable.

## What Carpenter is

Carpenter is a semantic UI platform for Flutter applications across desktop,
web, and mobile. It will provide domain-scoped roles, reusable interaction,
structured data views, adaptive semantic regions, and task-oriented patterns.

## What Carpenter is not

Carpenter is not an application framework, state-management framework, ORM,
backend, or a generic wrapper around all Flutter widgets.

## Platforms

Carpenter targets Flutter desktop, web, and mobile applications.

## Installation

Carpenter has not been published to pub.dev yet. Use a local path dependency
while developing against this repository.

## Current usage

```dart
import 'package:carpenter/carpenter.dart';
```

The initial development release does not yet export functional UI components.

## Development

Run the package checks from the repository root:

```sh
flutter pub get
flutter analyze
flutter test
```

## Example

The [development example](example/README.md) verifies installation as an
external Flutter dependency and will host future reference integrations.

## Widgetbook

The separate `widgetbook/` application is the development catalog for future
Carpenter components. It is not part of the published package.

## License

The project license is provided in [LICENSE](LICENSE).
