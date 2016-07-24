defmodule JaSerializer.Builder.Relationship do
  @moduledoc false

  alias JaSerializer.Builder.Link
  alias JaSerializer.Builder.ResourceIdentifier

  defstruct [:name, :links, :data, :meta]

  def build(%{serializer: serializer, data: data, conn: conn, opts: opts} = context) do
    case opts[:relationships] do
      false -> []
      _ -> Enum.map serializer.relationships(data, conn), &(build(&1, context))
    end
  end

  def build({name, definition}, context) do
    definition = Map.put(definition, :name, name)
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

  defp should_have_identifiers?(%{type: nil, serializer: nil}, _c),
    do: false
  defp should_have_identifiers?(%{type: _t, serializer: nil}, _c),
    do: true
  defp should_have_identifiers?(%{serializer: _s, identifiers: :always}, _c),
    do: true
  defp should_have_identifiers?(%{serializer: _s, identifiers: :when_included, name: name, include: true}, context) do
    case context[:opts][:include] do
      nil  -> true
      includes -> is_list(includes[name])
    end
  end
  defp should_have_identifiers?(%{serializer: _s, identifiers: :when_included, name: name}, context) do
    case context[:opts][:include] do
      nil  -> false
      includes -> is_list(includes[name])
    end
  end
end
