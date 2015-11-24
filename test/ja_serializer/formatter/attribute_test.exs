defmodule JaSerializer.Formatter.AttributeTest do
  use ExUnit.Case

  @attr JaSerializer.Builder.Attribute

  defmodule Example do
    defstruct [:foo, :bar]
  end

  defimpl JaSerializer.Formatter, for: [Example, Map] do
    def format(%{foo: foo, bar: bar}), do: [foo, bar] |> Enum.join("")
    def format(%{} = map), do: map
  end

  test "allows overriding for struct formatting" do
    assert {"example", "foobar"} == JaSerializer.Formatter.format(%@attr{
      key: :example,
      value:  %Example{foo: "foo", bar: "bar"}
    })
  end

  test "map formatter can be changed" do
    results = JaSerializer.Formatter.format(%@attr{
      key: :example,
      value:  %{foo: "foo", bar: "bar"}
    })

    assert {"example", "foobar"} == results
  end
end
