defmodule JaSerializer.Builder.ResourceIdentifier do
  @moduledoc false

  defstruct [:id, :type, :meta]

  def build(context, definition) do
    case get_data(context, definition) do
      [] -> [:empty_relationship]
      nil -> :empty_relationship
      many when is_list(many) -> Enum.map(many, &do_build(&1, context, definition))
      one -> do_build(one, context, definition)
    end
  end

  defp get_data(_, %{data: nil}), do: nil
  defp get_data(context, %{data: data}) when is_atom(data) do
    context.serializer
    |> apply(data, [context.data, context.conn])
  end
  defp get_data(_, %{data: data}), do: data

  defp do_build(data, context, definition) do
    %__MODULE__{
      type: find_type(data, context, definition),
      id: find_id(data, context, definition)
    }
  end

  defp find_id(%{} = data, _context, %{serializer: nil}) do
    Map.get(data, :id)
  end
  defp find_id(%{} = data, context, %{serializer: serializer}) do
    serializer.id(data, context.conn)
  end
  defp find_id(id, _, _), do: id

  defp find_type(_data, _context, %{type: type, serializer: nil}), do: type
  defp find_type(data, context, %{serializer: serializer}) do
    case serializer.type(data, context.conn) do
      type_fun when is_function(type_fun) ->
        IO.write :stderr, IO.ANSI.format([:red, :bright,
          "warning: returning an anonymous function from type/0 is " <>
          "deprecated. Please use the `type/2` callback instead.\n" <>
          Exception.format_stacktrace()
        ])
        type_fun.(data, context.conn)
      type -> type
    end
  end

end
