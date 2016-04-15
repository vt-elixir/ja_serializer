defmodule JaSerializer.DynamicTypeTest do
  use ExUnit.Case

  @wilbur %{id: 1, name: "Wilbur", type: "pig"}
  @charlotte %{id: 1, name: "Charlotte", type: "spider"}
  @farm %{ id: 1,
           name: "Green Acres",
           animals: [@wilbur, @charlotte],
           special_animal: @wilbur }

  defmodule AnimalSerialzer do
    use JaSerializer.Serializer
    attributes [:name]
    def type, do: fn(animal, _conn) -> animal.type end
  end

  defmodule FarmSerialzer do
    use JaSerializer.Serializer
    attributes [:name]
    has_many :animals, serializer: AnimalSerialzer
    has_one :special_animal, serializer: AnimalSerialzer
  end

  test "dynamically assigns the type for single item" do
    wilbur = AnimalSerialzer.format(@wilbur)
    assert wilbur.data.type == "pig"
  end

  test "works for multiple items" do
    animals = AnimalSerialzer.format([@wilbur, @charlotte])
    assert animals.data |> Enum.map(&(&1.type)) == ~w(pig spider)
  end

  test "works with 'has_many' relationship data" do
    farm = FarmSerialzer.format(@farm)
    animals = farm.data.relationships["animals"].data |> Enum.map(&(&1.type))
    assert "pig" in animals
    assert "spider" in animals
  end

  test "works with 'has_one' relationship data" do
    farm = FarmSerialzer.format(@farm)
    assert farm.data.relationships["special-animal"].data.type == "pig"
  end
end
