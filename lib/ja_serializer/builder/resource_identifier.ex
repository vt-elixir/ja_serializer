defmodule JaSerializer.Builder.ResourceIdentifier do
  @moduledoc false

  defstruct [:id, :type, :meta]

  def build(context, type, definition) do
    case get_data(context, definition) do
      [] -> [:empty_relationship]
      nil -> :empty_relationship
      many when is_list(many) -> Enum.map(many, &do_build(&1, type, context))
      one -> do_build(one, type, context)
    end
  end

  defp get_data(_, %{data: nil}), do: nil
  defp get_data(context, %{data: data}) when is_atom(data) do
    context.serializer
    |> apply(data, [context.data, context.conn])
  end
  defp get_data(_, %{data: data}), do: data

  defp do_build(data, type, context) do
    %__MODULE__{
      type: find_type(data, type, context),
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

  defp find_type(data, type, context) when is_function(type) do
    type.(data, context.conn)
  end

  defp find_type(_, type, _), do: type
end
