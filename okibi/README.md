# Okibi

Okibi is the application workspace embedded in the Carpenter repository. It
depends on Carpenter through a local path dependency while keeping product and
domain code outside the reusable UI package.
Its application root uses Flutter widgets and Carpenter only: it has no
Material or Cupertino dependency.

## Run

```sh
cd okibi
flutter run
```

## Verify

```sh
cd okibi
flutter analyze
flutter test
```
