defmodule JaSerializer.Formatter.AttributeTest do
  use ExUnit.Case
  alias JaSerializer.Formatter.Utils

  @attr JaSerializer.Builder.Attribute

  defmodule Example do
    defstruct [:foo, :bar]
  end

  defmodule NestedExample do
    defstruct [:nested_map, :nested_list]
  end

  defmodule SimpleSerializer do
    def type(_, _), do: "simple"
    def attributes(data, _), do: data
  end

  defimpl JaSerializer.Formatter, for: [Example, Map] do
    def format(%{foo: foo, bar: bar}), do: [foo, bar] |> Enum.join("")
    def format(%{} = map), do: map
  end

  defimpl JaSerializer.Formatter,
    for: [NestedExample] do
    def format(%{nested_map: map}) when is_map(map) do
      values = Utils.deep_format_keys(map)
      JaSerializer.Formatter.format(values)
    end

    def format(%{nested_list: list}) when is_list(list) do
      values = Utils.deep_format_keys(list)
      JaSerializer.Formatter.format(values)
    end
  end

  test "allows overriding for nested map formatting" do
    assert {"some-example", %{"nested-layer1" => %{"nested-layer2" => "123"}}} ==
             JaSerializer.Formatter.format(%@attr{
               key: :some_example,
               value: %NestedExample{
                 nested_map: %{nested_layer1: %{nested_layer2: "123"}}
               }
             })
  end

  test "allows overriding for nested list formatting" do
    assert {"some-example",
            [
              %{"nested-map" => %{"nested-layer2" => "123"}},
              %{"nested-map" => %{"nested-layer2" => "456"}}
            ]} ==
             JaSerializer.Formatter.format(%@attr{
               key: :some_example,
               value: %NestedExample{
                 nested_list: [
                   %{nested_map: %{nested_layer2: "123"}},
                   %{nested_map: %{nested_layer2: "456"}}
                 ]
               }
             })
  end

  test "allows overriding for struct formatting" do
    assert {"example", "foobar"} ==
             JaSerializer.Formatter.format(%@attr{
               key: :example,
               value: %Example{foo: "foo", bar: "bar"}
             })
  end

  test "map formatter can be changed" do
    results =
      JaSerializer.Formatter.format(%@attr{
        key: :example,
        value: %{foo: "foo", bar: "bar"}
      })

    assert {"example", "foobar"} == results
  end

  test "the correct keys are filtered out with build" do
    context = %{
      data: %{key_1: 1, key_2: 2, key_3: 3},
      serializer: SimpleSerializer,
      conn: nil,
      opts: [fields: %{"simple" => "key_2,key_3"}]
    }

    result = @attr.build(context)

    refute :key_1 in Enum.map(result, & &1.key)
    assert :key_2 in Enum.map(result, & &1.key)
    assert :key_3 in Enum.map(result, & &1.key)
  end

  test "the correct keys are are filtered when given a list" do
    context = %{
      data: %{key_1: 1, key_2: 2, key_3: 3},
      serializer: SimpleSerializer,
      conn: nil,
      opts: [fields: %{"simple" => [:key_2, :key_3]}]
    }

    result = @attr.build(context)

    refute :key_1 in Enum.map(result, & &1.key)
    assert :key_2 in Enum.map(result, & &1.key)
    assert :key_3 in Enum.map(result, & &1.key)
  end

  test "the nested attributes are formatted" do
    context = %{
      data: %{
        map_data: %NestedExample{
          nested_map: %{nested_layer1: %{nested_layer2: "123"}}
        },
        list_data: %NestedExample{
          nested_list: [
            %{nested_map: %{nested_layer2: "123"}},
            %{nested_map: %{nested_layer2: "456"}}
          ]
        }
      },
      serializer: SimpleSerializer,
      conn: nil
    }

    result = @attr.build(context) |> JaSerializer.Formatter.format()

    assert result == [
             {"list-data",
              [
                %{"nested-map" => %{"nested-layer2" => "123"}},
                %{"nested-map" => %{"nested-layer2" => "456"}}
              ]},
             {"map-data", %{"nested-layer1" => %{"nested-layer2" => "123"}}}
           ]
  end
end
