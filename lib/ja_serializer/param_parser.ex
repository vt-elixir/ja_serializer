defprotocol JaSerializer.ParamParser do
  @dialyzer {:nowarn_function, __protocol__: 1}
  @fallback_to_any true
  def parse(params)
end

defimpl JaSerializer.ParamParser, for: Any do
  def parse(data), do: data
end

defimpl JaSerializer.ParamParser, for: List do
  def parse(list), do: Enum.map(list, &JaSerializer.ParamParser.parse/1)
end

# Pass built in data types through
defimpl JaSerializer.ParamParser, for: [BitString, Integer, Float, Atom, Function, PID, Port, Reference, Tuple] do
  def parse(data), do: data
end

defimpl JaSerializer.ParamParser, for: Plug.Upload do
  def parse(data), do: data
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
  @moduledoc false

  def format_key(key) do
    case Application.get_env(:ja_serializer, :key_format, :dasherized) do
      :dasherized  -> dash_to_underscore(key)
      :underscored -> key
      _ -> key
    end
  end

  defp dash_to_underscore(key), do: String.replace(key, "-", "_")
end
