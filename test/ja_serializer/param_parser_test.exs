defmodule JaSerializer.ParamParserTest do
  use ExUnit.Case

  import JaSerializer.ParamParser, only: [parse: 1]

  setup do
    on_exit(fn ->
      Application.delete_env(:ja_serializer, :key_format)
    end)

    :ok
  end

  test "attribute and relationship keys are converted" do
    params = %{
      "data" => %{
        "type" => "example",
        "id" => "one",
        "attributes" => %{
          "some-nonsense" => true,
          "foo-bar" => "unaffected-values",
          "some-map" => %{
            "nested-key" => "unaffected-values"
          }
        },
        "relationships" => %{
          "my-model" => %{
            "links" => %{"related" => "/api/my_model/1"},
            "data" => %{"type" => "my_model", "id" => "1"}
          },
          "plural_models" => %{
            "links" => %{"related" => "/api/examples/one/plural_models"},
            "data" => [
              %{"type" => "plural_model", "id" => "1"},
              %{"type" => "plural_model", "id" => "2"}
            ]
          }
        }
      }
    }

    params_with_custom_keys = %{
      "data" => %{
        "type" => "example",
        "id" => "one",
        "attributes" => %{
          "someNonsense" => true,
          "fooBar" => "unaffected-values",
          "someMap" => %{
            "nestedKey" => "unaffected-values"
          }
        },
        "relationships" => %{
          "myModel" => %{
            "links" => %{"related" => "/api/my_model/1"},
            "data" => %{"type" => "my_model", "id" => "1"}
          },
          "pluralModels" => %{
            "links" => %{"related" => "/api/examples/one/plural_models"},
            "data" => [
              %{"type" => "plural_model", "id" => "1"},
              %{"type" => "plural_model", "id" => "2"}
            ]
          }
        }
      }
    }

    expected = %{
      "data" => %{
        "type" => "example",
        "id" => "one",
        "attributes" => %{
          "some_nonsense" => true,
          "foo_bar" => "unaffected-values",
          "some_map" => %{
            "nested_key" => "unaffected-values"
          }
        },
        "relationships" => %{
          "my_model" => %{
            "links" => %{"related" => "/api/my_model/1"},
            "data" => %{"type" => "my_model", "id" => "1"}
          },
          "plural_models" => %{
            "links" => %{"related" => "/api/examples/one/plural_models"},
            "data" => [
              %{"type" => "plural_model", "id" => "1"},
              %{"type" => "plural_model", "id" => "2"}
            ]
          }
        }
      }
    }

    assert parse(params) == expected

    Application.put_env(:ja_serializer, :key_format, :underscored)
    assert parse(params) == params

    Application.put_env(:ja_serializer, :key_format, :camel_cased)
    assert parse(params_with_custom_keys) == expected

    Application.put_env(
      :ja_serializer,
      :key_format,
      {:custom, Macro, nil, :underscore}
    )

    assert parse(params_with_custom_keys) == expected
  end

  test "converts query param key names" do
    params = %{
      "page" => %{
        "page-size" => ""
      },
      "filter" => %{
        "foo-attr" => "val"
      }
    }

    params_with_custom_keys = %{
      "page" => %{
        "pageSize" => ""
      },
      "filter" => %{
        "fooAttr" => "val"
      }
    }

    expected = %{
      "page" => %{
        "page_size" => ""
      },
      "filter" => %{
        "foo_attr" => "val"
      }
    }

    assert parse(params) == expected

    Application.put_env(:ja_serializer, :key_format, :underscored)
    assert parse(params) == params

    Application.put_env(
      :ja_serializer,
      :key_format,
      {:custom, Macro, nil, :underscore}
    )

    assert parse(params_with_custom_keys) == expected
  end

  test "uploads are not effected" do
    params = %{
      "foo-key" => %Plug.Upload{filename: "foo.bar"}
    }

    expected = %{
      "foo_key" => %Plug.Upload{filename: "foo.bar"}
    }

    assert parse(params) == expected
  end
end
