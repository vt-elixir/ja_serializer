defmodule JaSerializer.Builder.ResourceObject do
  @moduledoc false

  alias JaSerializer.Builder.Attribute
  alias JaSerializer.Builder.Relationship
  alias JaSerializer.Builder.Link

  defstruct [
    :id,
    :type,
    :attributes,
    :relationships,
    :relationship_definitions,
    :links,
    :meta,
    :data
  ]

  def build(%{data: data} = context) when is_list(data) do
    Enum.map(data, fn struct ->
      context
      |> Map.put(:data, struct)
      |> build
    end)
  end

  def build(%{serializer: serializer} = context) do
    rel_definitions =
      if context[:opts][:relationships] == false do
        nil
      else
        serializer.relationships(context.data, context.conn)
      end

    context_with_rels =
      Map.put(context, :relationship_definitions, rel_definitions)

    %__MODULE__{
      id: serializer.id(context.data, context.conn),
      type: __type(serializer.type(context.data, context.conn), context),
      data: context.data,
      attributes: Attribute.build(context),
      relationships: Relationship.build(context_with_rels),
      relationship_definitions: rel_definitions,
      links: Link.build(context),
      meta: serializer.meta(context.data, context.conn)
    }
  end

  defp __type(type, context) when is_function(type),
    do: type.(context.data, context.conn)

  defp __type(type, _), do: type
end
