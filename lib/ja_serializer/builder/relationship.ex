defmodule JaSerializer.Builder.Relationship do
  @moduledoc false

  alias JaSerializer.Builder.Link
  alias JaSerializer.Builder.ResourceIdentifier

  defstruct [:name, :links, :data, :meta]

  def build(%{serializer: serializer, data: data, conn: conn} = context) do
    Enum.map serializer.relationships(data, conn), &(build(&1, context))
  end

  defp build({name, definition}, context) do
    %__MODULE__{name: name}
    |> add_links(definition, context)
    |> add_data(definition, context)
  end

  defp add_links(relation, definition, context) do
    definition.links
      |> Enum.map(fn {key, path} -> Link.build(context, key, path) end)
      |> case do
        []   ->  relation
        links -> Map.put(relation, :links, links)
      end
  end

  defp add_data(relation, definition, context) do
    case determine_type(definition) do
      nil  -> relation
      type ->
        context = Map.put(context, :resource_serializer, definition.serializer)
        Map.put(relation, :data, ResourceIdentifier.build(context, type, definition))
    end
  end

  defp determine_type(definition) do
    case {definition.type, definition.serializer} do
      {nil, nil}        -> nil
      {nil, serializer} -> apply(serializer, :type, [])
      {type, _}         -> type
    end
  end
end
