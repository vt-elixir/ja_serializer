defmodule JaSerializer.Builder.Link do
  @moduledoc false

  defstruct href: nil, meta: nil, type: :related

  def build(context) do
    context.serializer.links(context.data, context.conn)
    |> Enum.map(fn({type, path}) -> build(context, type, path) end)
  end

  def build(_context, _type, nil), do: nil

  def build(context, type, path) when is_binary(path) do
    %__MODULE__{
      href: path,
      type: type
    }
  end

  def build(context, type, path) when is_atom(path) do
    %__MODULE__{
      href: apply(context.serializer, path, [context.data, context.conn]),
      type: type
    }
  end
end
