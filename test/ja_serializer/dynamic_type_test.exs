defmodule JaSerializer.DynamicTypeTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  @wilbur %{id: 1, name: "Wilbur", type: "pig"}
  @charlotte %{id: 1, name: "Charlotte", type: "spider"}
  @farm %{
    id: 1,
    name: "Green Acres",
    animals: [@wilbur, @charlotte],
    special_animal: @wilbur
  }
  @expected_error "warning: returning an anonymous function from type/0 is deprecated. Please use the `type/2` callback instead."

  defmodule AnimalSerializer do
    use JaSerializer
    attributes([:name])
    def type, do: fn animal, _conn -> animal.type end
  end

  defmodule FarmSerializer do
    use JaSerializer
    attributes([:name])
    has_many(:animals, serializer: AnimalSerializer, identifiers: :always)
    has_one(:special_animal, serializer: AnimalSerializer)
  end

  test "dynamically assigns the type for single item" do
    error_output =
      capture_io(:stderr, fn ->
        wilbur = JaSerializer.format(AnimalSerializer, @wilbur)
        assert wilbur["data"]["type"] == "pig"
      end)

    error_output =~ @expected_error
  end

  test "works for multiple items" do
    error_output =
      capture_io(:stderr, fn ->
        animals = JaSerializer.format(AnimalSerializer, [@wilbur, @charlotte])
        assert animals["data"] |> Enum.map(& &1["type"]) == ~w(pig spider)
      end)

    assert error_output == ""
  end

  test "works with 'has_many' relationship data" do
    error_output =
      capture_io(:stderr, fn ->
        farm = JaSerializer.format(FarmSerializer, @farm)

        animals =
          farm["data"]["relationships"]["animals"]["data"]
          |> Enum.map(& &1["type"])

        assert "pig" in animals
        assert "spider" in animals
      end)

    assert error_output =~ @expected_error
  end

  test "works with 'has_one' relationship data" do
    error_output =
      capture_io(:stderr, fn ->
        farm = JaSerializer.format(FarmSerializer, @farm)

        assert farm["data"]["relationships"]["special-animal"]["data"]["type"] ==
                 "pig"
      end)

    assert error_output =~ @expected_error
  end
end
