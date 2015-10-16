defmodule JaSerializer.Builder.ResourceIdentifier do
  @moduledoc false

  defstruct [:id, :type, :meta]

  def build(%{serializer: serializer} = context, type, name) do
    serializer
    |> apply(name, [context.model, context.conn])
    |> case do
      [] -> [:empty_relationship]
      nil -> :empty_relationship
      many when is_list(many) -> Enum.map(many, &build(&1, type))
      one -> build(one, type)
    end
  end

  def build(%{} = model, type) do
    %__MODULE__{
      type: type,
      id: Map.get(model, :id)
    }
  end

  def build(id, type) do
    %__MODULE__{
      type: type,
      id: id
    }
  end
end
