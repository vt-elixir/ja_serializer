defmodule JaSerializer.Builder.ResourceObject do
  @moduledoc false

  alias JaSerializer.Builder.Attribute
  alias JaSerializer.Builder.Relationship
  alias JaSerializer.Builder.Link

  defstruct [:id, :type, :attributes, :relationships, :links, :meta, :data]

  def build(%{data: data} = context) when is_list(data) do
    Enum.map data, fn(struct) ->
      context
      |> Map.put(:data, struct)
      |> build
    end
  end

  def build(%{serializer: serializer} = context) do
    %__MODULE__{
      id:            serializer.id(context.data, context.conn),
      type:          serializer.type,
      data:          context.data,
      attributes:    Attribute.build(context),
      relationships: Relationship.build(context),
      links:         [Link.build(context, :self, serializer.__location)],
      meta:          serializer.meta(context.data, context.conn)
    }
  end
end
