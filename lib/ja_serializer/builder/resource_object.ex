defmodule JaSerializer.Builder.ResourceObject do
  @moduledoc false

  alias JaSerializer.Builder.Attribute
  alias JaSerializer.Builder.Relationship
  alias JaSerializer.Builder.Link

  defstruct [:id, :type, :attributes, :relationships, :links, :meta, :model]

  def build(%{model: models} = context) when is_list(models) do
    Enum.map models, fn(model) ->
      context
      |> Map.put(:model, model)
      |> build
    end
  end

  def build(%{serializer: serializer} = context) do
    %__MODULE__{
      id:            apply(serializer, :id, [context.model, context.conn]),
      type:          serializer.__type_key,
      model:         context.model,
      attributes:    Attribute.build(context),
      relationships: Relationship.build(context),
      links:         [Link.build(context, :self, serializer.__location)]
    }
  end
end
