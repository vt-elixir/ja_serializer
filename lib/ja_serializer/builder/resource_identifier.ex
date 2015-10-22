defmodule JaSerializer.Builder.ResourceIdentifier do
  @moduledoc false

  defstruct [:id, :type, :meta]

  def build(%{serializer: serializer} = context, type, name) do
    serializer
    |> apply(name, [context.model, context.conn])
    |> case do
      [] -> [:empty_relationship]
      nil -> :empty_relationship
      many when is_list(many) -> Enum.map(many, &build(&1, type, context))
      one -> build(one, type, context)
    end
  end

  def build(%{} = model, type, %{resource_serializer: resource_serializer} = context) do
    id = cond do
      resource_serializer ->
        apply(resource_serializer, :id, [model, context.conn])
      true ->
        Map.get(model, :id)
    end

    build(id, type)
  end

  def build(%{} = model, type) do
    id = Map.get(model, :id)

    build(id, type)
  end

  def build(id, type) do
    %__MODULE__{
      type: type,
      id: id
    }
  end
end
