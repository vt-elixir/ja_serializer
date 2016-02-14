defmodule JaSerializer.ParamParserTest do
  use ExUnit.Case

  import JaSerializer.ParamParser, only: [parse: 1]

  setup do
    on_exit fn ->
      Application.delete_env(:ja_serializer, :key_format)
    end
    :ok
  end

  test "attribute and relationship keys are converted" do
    params = %{
      "data" => %{
        "type" => "example",
        "id"   => "one",
        "attributes" => %{
          "some-nonsense" => true,
          "foo-bar" => "unaffected-values",
          "some-map" => %{
            "nested-key" => "unaffected-values"
          }
        },
        "relationships" => %{
          "my-model" => %{
            "links" => %{ "related" => "/api/my_model/1" },
            "data" => %{ "type" => "my_model", "id" => "1" }
          }
        }
      }
    }
    expected = %{
      "data" => %{
        "type" => "example",
        "id"   => "one",
        "attributes" => %{
          "some_nonsense" => true,
          "foo_bar" => "unaffected-values",
          "some_map" => %{
            "nested_key" => "unaffected-values"
          }
        },
        "relationships" => %{
          "my_model" => %{
            "links" => %{ "related" => "/api/my_model/1" },
            "data" => %{ "type" => "my_model", "id" => "1" }
          }
        }
      }
    }

    assert parse(params) == expected

    Application.put_env(:ja_serializer, :key_format, :underscored)

    assert parse(params) == params
  end

  test "converts query param key names" do
    params = %{
      "page" => %{
        "page-size" => "",
      },
      "filter" => %{
        "foo-attr" => "val"
      }
    }

    expected = %{
      "page" => %{
        "page_size" => "",
      },
      "filter" => %{
        "foo_attr" => "val"
      }
    }

    assert parse(params) == expected

    Application.put_env(:ja_serializer, :key_format, :underscored)

    assert parse(params) == params
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
