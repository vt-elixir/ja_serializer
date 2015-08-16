# Changelog

## v0.2.0

* Features:
  * Add Phoenix integration w/ JaSerializer.PhoenixView.
  * Infer type from module name.
  * Add `attributes/2` callback w/ default implementation based on `attributes/1` macro.
  * Add JaSerializer.ContentTypeNegotiation plug for setting content type.
  * Add JaSerializer.Deserializer plug for param normalization.
* Deprecations:
  * Remove `serialize` macro in favor of `type/0` callback.

## v0.1.2

* Bugfix
  * Added non-fallback formatters for simple data types to improve out of the box performance.

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
