defprotocol JaSerializer.ParamParser do
  @fallback_to_any true
  def parse(params)
end

defimpl JaSerializer.ParamParser, for: Any do
  def parse(data), do: data
end

defimpl JaSerializer.ParamParser, for: List do
  def parse(list), do: Enum.map(list, &JaSerializer.ParamParser.format/1)
end

defimpl JaSerializer.ParamParser, for: [BitString, Integer, Float, Atom] do
  def parse(data), do: data
end

if Code.ensure_loaded?(Plug) do
  defimpl JaSerializer.ParamParser, for: Plug.Upload do
    def parse(data), do: data
  end
end

defimpl JaSerializer.ParamParser, for: Map do
  def parse(map) do
    Enum.reduce map, %{}, fn({key, val}, map) ->
      key = JaSerializer.ParamParser.Utils.format_key(key)
      Map.put(map, key, JaSerializer.ParamParser.parse(val))
    end
  end
end

defmodule JaSerializer.ParamParser.Utils do
  def format_key(key) do
    case Application.get_env(:ja_serializer, :key_format, :dasherized) do
      :dasherized  -> dash_to_underscore(key)
      :underscored -> key
      _ -> key
    end
  end

  defp dash_to_underscore(key), do: String.replace(key, "-", "_")
end
