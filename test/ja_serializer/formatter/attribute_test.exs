defmodule JaSerializer.Formatter.AttributeTest do
  use ExUnit.Case

  @attr JaSerializer.Builder.Attribute

  defmodule Example do
    defstruct [:foo, :bar]
  end

  defmodule SimpleSerializer do
    def type(_, _), do: "simple"
    def attributes(data, _), do: data
  end

  defimpl JaSerializer.Formatter, for: [Example, Map] do
    def format(%{foo: foo, bar: bar}), do: [foo, bar] |> Enum.join("")
    def format(%{} = map), do: map
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
end
