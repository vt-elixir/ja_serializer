defmodule JaSerializer.Builder.Attribute do
  @moduledoc false

  defstruct [:key, :value]

  def build(context) do
    context
    |> attributes
    |> filter_fields(context)
    |> Enum.map(&do_build/1)
  end

  defp attributes(%{serializer: serializer, data: data, conn: conn}) do
    serializer.attributes(data, conn)
  end

  defp filter_fields(attrs, context = %{serializer: serializer, opts: opts}) do
    case opts[:fields] do
      fields when is_map(fields) -> do_filter(attrs, fields[serializer.type(context.data, context.conn)])
      _any -> attrs
    end
  end
  defp filter_fields(attrs, _), do: attrs

  defp do_filter(attrs, nil), do: attrs
  defp do_filter(attrs, fields) when is_list(fields),
    do: Map.take(attrs, fields)
  defp do_filter(attrs, fields) when is_binary(fields),
    do: do_filter(attrs, safe_atom_list(fields))

  defp safe_atom_list(field_str) do
    field_str |> String.split(",") |> Enum.map(&String.to_existing_atom/1)
  end

  defp do_build({key, value}), do: %__MODULE__{key: key, value: value}
end
