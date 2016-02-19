defmodule JaSerializer.Builder.ResourceIdentifier do
  @moduledoc false

  defstruct [:id, :type, :meta]

  def build(%{serializer: serializer} = context, type, name) do
    serializer
    |> apply(name, [context.data, context.conn])
    |> case do
      [] -> [:empty_relationship]
      nil -> :empty_relationship
      many when is_list(many) -> Enum.map(many, &do_build(&1, type, context))
      one -> do_build(one, type, context)
    end
  end

  defp do_build(data, type, context) do
    %__MODULE__{
      type: type,
      id: find_id(data, context)
    }
  end

  defp find_id(%{} = data, %{resource_serializer: nil}) do
    Map.get(data, :id)
  end

  defp find_id(%{} = data, context = %{resource_serializer: serializer}) do
    apply(serializer, :id, [data, context.conn])
  end

  defp find_id(id, _), do: id
end
