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
    if should_have_identifiers?(definition, context) do
      Map.put(relation, :data, ResourceIdentifier.build(context, definition))
    else
      relation
    end
  end

  defp should_have_identifiers?(%{type: nil, serializer: nil}, _context), do: false
  defp should_have_identifiers?(%{type: nil, serializer: _serializer}, _context) do
    # TODO, there should be some way to have this optionally included.
    true
  end
  defp should_have_identifiers?(_definition, _context), do: true
end
