# Changelog

## v0.2.0 - Dev

* Features:
  * Add Phoenix integration w/ JaSerializer.PhoenixView.
  * Infer type from module name.
  * Add `attributes/2` callback w/ default implementation based on `attributes/1` macro.
* Deprecations:
  * Remove `serialize` macro in favor of `type/0` callback.

## v0.1.1

* Bugfixes:
  * Fix issues w/ include chains that resulted in infinite loops.

## v0.1.0

* Features:
  * Add config option for formatting keys as underscored or dasherized.
* Bugfixes:
  * Serialize include chains w/o duplicates.

## v0.0.1

* Initial release.
