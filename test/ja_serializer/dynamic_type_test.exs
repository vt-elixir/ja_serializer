defmodule JaSerializer.DynamicTypeTest do
  use ExUnit.Case

  defmodule AnimalSerialzer do
    use JaSerializer.Serializer
    attributes [:name]
    def type, do: fn(animal, _conn) -> animal.type end
  end

  @wilbur %{name: "Wilbur", type: "pig"}
  @charlotte %{name: "Charlotte", type: "spider"}

  test "dynamically assigns the type for single item" do
    wilbur = AnimalSerialzer.format(@wilbur)
    assert wilbur.data.type == "pig"
  end

  test "works for multiple items" do
    animals = AnimalSerialzer.format([@wilbur, @charlotte])
    assert animals.data |> Enum.map(&(&1.type)) == ~w(pig spider)
  end
end
