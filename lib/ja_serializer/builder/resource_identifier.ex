defmodule JaSerializer.Builder.ResourceIdentifier do
  @moduledoc false

  defstruct [:id, :type, :meta]

  def build(%{serializer: serializer} = context, type, name) do
    serializer
    |> apply(name, [context.model, context.conn])
    |> case do
      [] -> [:empty_relationship]
      nil -> :empty_relationship
      many when is_list(many) -> Enum.map(many, &do_build(&1, type, context))
      one -> do_build(one, type, context)
    end
  end

  defp do_build(model, type, context) do
    %__MODULE__{
      type: type,
      id: find_id(model, context)
    }
  end

  defp find_id(%{} = model, %{resource_serializer: nil}) do
    Map.get(model, :id)
  end

  defp find_id(%{} = model, context = %{resource_serializer: serializer}) do
    apply(serializer, :id, [model, context.conn])
  end

  defp find_id(id, _), do: id
end
