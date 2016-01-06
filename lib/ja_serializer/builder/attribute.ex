defmodule JaSerializer.Builder.Attribute do
  @moduledoc false

  defstruct [:key, :value]

  def build(context) do
    context
    |> fields_to_include
    |> Enum.map(&do_build/1)
  end

  def fields_to_include(%{model: model, serializer: serializer, conn: conn} = context) do
    attrs = apply(serializer,:attributes, [model, conn])
    field_map = context[:opts][:fields] || %{}
    attrs_to_include = Map.get(field_map, serializer.type)

    cond do
      attrs_to_include ->
        include_list = String.split(attrs_to_include, ",") |> Enum.map(&String.to_atom/1)
        Enum.filter attrs, fn({key, _value}) -> key in include_list end
      true ->
        attrs
    end
  end

  def do_build({key, value}), do: %__MODULE__{key: key, value: value}
end
