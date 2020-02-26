# Changelog

## Unreleased

### Feature
  * Raise exception when using a reserved keyword in attributes/1 macro

### Breaking
  * Removed JaSerializer generators in favor of documenting how to use with
    Phoenix generators.

## v0.15.0

### Features
  * Add optional support for camelCase key format as recommended by
    JSON:API v1.1 - #316/#317
  * Make JaSerializer.TopLevel.Builder.normalize_includes/1 public - #323

### Bug fixes
  * Allow accept header with quality param - #320
  * Include relationships in sparse field definition - #324

### Breaking
  * Don't render empty relationships - #311
  * Omit prev/next links when current page is > last page - #317
  * Don't raise AssociationNotLoadedError if belongs to relationship can
    be determined. - #322

The following workaround is no longer needed:

```
has_one :city, serializer: MyApp.CityView

def city(%{city: %Ecto.Association.NotLoaded{}, city_id: nil}, _conn), do: nil
def city(%{city: %Ecto.Association.NotLoaded{}, city_id: id}, _conn), do: %{id: id}
def city(%{city: city}, _conn), do: city
```

## v0.14.1

### Bug fixes
  * Fix application start up w/out Poison - #310

## v0.14.0

### Breaking
  * Only include attributes key when there are attributes present - #297
  * Serializer attribute and relationship function overrides must be public.
  Previously there was an untested/undocumented way of overriding attributes with
  private functions, but this is no longer supported.

In other words, change this:

```
defmodule PostSerializer do
  use JaSerializer, dsl: true
  attributes [:html]

  defp html(post, _conn) do
    Earmark.to_html(post.body)
  end
end
```

to this:

```
defmodule PostSerializer do
  use JaSerializer, dsl: true
  attributes [:html]

  def html(post, _conn) do
    Earmark.to_html(post.body)
  end
end
```

### Features
  * Read key format config value at runtime - #265

### Bug fixes
  * Build pagination URLs using base url and request path - #281
  * Issue rendering some ecto changeset errors - #275
  * Handle the case where the end of a link is a URI fragment - #293
  * Added missing @callback in Serializer - #294
  * Consistent relation override - #299
  * Fix compilation error when defining already inlined by compiler methods - #304

### Misc
  * Add .formatter.exs for consistent formatting
  * Fixed compiler warnings
  * Use `capture_io` in tests to make output less noisy

## v0.13.0

### Breaking
  * Add JaSerializer.Builder.PaginationLinks (@bcardarella) - #233
    * `page_number_key` defaults to number instead of `page`
    * `page_size_key` defaults to size instead of `page-size`
    * `scrivener_base_url` renamed to `page_base_url`

### Features
  * Allow serializing null structs (@juanazam) - #181
  * Preserve ID in `to_attributes/1` (@xtian) - #254
  * Allow API to produce pluralized types rather than having to configure
each serializer one by one (@bcardarella) - #225
  * Generator task for Phoenix 1.3 (@mikeni) - #243

### Bugfixes
  * Fixed formatting of multi-word relationship path keys (@yogipatel) - #230
  * Page links are merged in correct order (@qbart) - #251
  * Fix an edge case with pagination links (@marpo60) - #252


### Performance
  * Improved performance of inline DSL attributes (@DocX) - #245

### Documentation
  * Fixes and improvements by @peterberkenbosch, @petehamilton, @beerlington

## v0.12.0
* **Breaking**
  * Elixir 1.1 and earlier no longer supported.
* Features
  * Elixir 1.4 support. (@yordis, @joshuataylor, @asummers)
  * Add `config :ja_serializer, scrivener_base_url:` support (@geolessel)
  * Support custom key deserialization (@vasilenko)

## v0.11.2
* Features
  * Allow customization of pagination params in Scrivener intergration (@scrogson)
* Bugfixes
  * Add json api version to error responses. (@nmcalabroso)
  * Support umbrella apps in generators. (@gullitmiranda)
  * Support {:array, :integer} type ecto fields in error serializer	(@henriquecf)


## v0.11.1
* Bugfixes
  * Handle port numbers in link urls. (@MishaConway)
* Documentations
  * Fixes and improvements by @archSeer, @JoshSmith, and @rynam0
* Misc
  * Cleaned up Credo reported code inconsistencies

## v0.11.0
* **Breaking**
  * The results of JaSerializer.format/4 now returns maps consitently keyed
    with binaries instead of mixed binaries and atoms. This is not an issue
    when rendering to json, but any direct testing of format/4 calls may need
    to be updated. (@bcardarella)
* Bugfixes
  * Ensure deep linked `include` query params are correctly rendered. (@KronicDeth)
  * Use `build_conn/0` instead of `conn/0` in Phoenix test generator (@dustinfarris)
  * Properly parse nill relationships when de-serializing params (@kaermorchen)
* Features
  * adds `:relationships` to serialization opts to skip serializing
    relationships. Defaults to true. (@bcardarella)
  * Adds preload/3 hook for preloading relationship data.
  * Support passing more fields to EctoErrorSerializer (@nurugger07)

## v0.10.1
* Features
  * Upgrade Scrivener for Ecto 2.0 & Scrivener support (@avitex)
* Bugfixes
  * Fix ecto error serialization for both 2.0 and 1.0 support (@KronicDeth)
* Deprecations
  * No longer supports Scrivener 1.x

## v0.10.0
* Features
  * There is a full behaviour for serializing, including relationships, with a DSL on top.
  * Adds type/2 hook for defining the object type.
* Performance
  * Scrivener link integration are now faster (@benfalk)
  * Parsing fields params is now more effecient (@benfalk)
* Deprecations
  * Prefer type/2 callback over type/0.
  * Returning functions from type/0 deprecated if favor of using type/2.
  * MySerializer.format/3 deprecated in favor of JaSerializer.format/4.
* Bugfixes
  * Fix generator imperative assignment warning. (@parndt)
  * Fix default dsl link imperative assignment warning. (@itsgreggreg)

## v0.9.0
* Features
  * Allow type to be set dynamically #94 (@benfalk)
  * Add JaSerializer.Params.to_attributes/1 for merging relationships and attributes
  * Add generator to generate json-api spec phoenix controllers and tests. (@Dreamer009)
* Bugfixes
  * Don't render all pagination links when only one page of results #96 (@adamboas)
  * Relax Ecto and Plug dependencies. (Ecto 2.0 support!)

## v0.8.1
* Performance
  * Improved performance of included (sideloaded) relationships. #86 (@dgvncsz0f)

## v0.8.0
* **Breaking**
  * You must now set the Phoenix :format_encoder for json-api to Poison in
    config.exs. Phoenix now handles conversion from map to json string.
    See README for details.
* Features
  * Allow Poison 2.0
* Bugfixes
  * Allow application/*, */* and empty accept headers without returning 406.
  * Count errors now display full message in description.
  * Fixed serializing lists - [#78](https://github.com/AgilionApps/ja_serializer/pull/78)

## v0.7.1
* Features
  * Param parsing now happens via a protocol for extensibility.

## v0.7.0
* **Breaking**
  * Pagination, sorting, filtering query param keys are now formatted with the
    configured key_format. This means the API outputs and expects dasherized by default. (@linstula)
* Features
  * Deprecations messages now consitently formatted and contain a stack trace. (@derekprior)

## v0.6.3
* Features
  * Type is now formatted as underscore or dasherized, same as your key setting. (@linstula)

## v0.6.2
* Features
  * Updates error serializer to include field name in description. (@cjbell)
* Bugfixes
  * Retain type information when deserializing. (@linstula)
  * Fix pipe warning in Elixir 1.2 (@bortevik)

## v0.6.1
* Features
  * Allow query params in link formatting. (@simonprev)
  * Deps added to application for exrm. (@dmarkow)
* Bugfixes
  * fomat_key typo in ecto_error_serializer (@gordonbisner)

## v0.6.0
* Features
  * Support json-api spec `include` query param. (@green-arrow)
  * Support json-api spec `fields` query param. (@green-arrow)
  * Add meta info support

## v0.5.0
* Features:
  * Support custom ids in relationships. (@green-arrow)
  * Adds error rendering support to Phoenix view.
* Deprecations:
  * Use key `serializer` instead of `include` when defining relationships.
* Dependencies:
  * Ecto is now a required (non-optional) dependency.

## v0.4.0
* Features:
  * Adds support for pagination links w/ Scrivener or via opts. (@vysakh0)
* Bugfixes:
  * Properly serialize empty relationships. (@dmarkow)

## v0.3.1

* Bugfixes
  * Adds optional Ecto dependency to fix compliation issue.

## v0.3.0

* **Breaking**:
  * Raises exception if ecto relationship is not pre-fetched.
* Features:
  * Adds JaSerializer.ErrorSerializer
  * Adds JaSerializer.EctoErrorSerializer
  * Pre-defines formats for Ecto built in types.

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
