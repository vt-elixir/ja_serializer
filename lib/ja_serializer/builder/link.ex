defmodule JaSerializer.Builder.Link do
  @moduledoc false

  @param_fetcher_regex ~r/:\w+/

  defstruct href: nil, meta: nil, type: :related

  def build(_context, _type, nil), do: nil

  def build(context, type, path) when is_binary(path) do
    %__MODULE__{
      href: path_for_context(context, path),
      type: type
    }
  end

  def build(context, type, path) when is_atom(path) do
    %__MODULE__{
      href: apply(context.serializer, path, [context.model, context.conn]),
      type: type
    }
  end

  defp path_for_context(context, path) do
    @param_fetcher_regex
    |> Regex.replace(path, &frag_for_context(&1, context))
  end

  defp frag_for_context(":" <> frag, %{serializer: serializer} = context) do
    "#{apply(serializer, String.to_atom(frag), [context.model, context.conn])}"
  end
end
