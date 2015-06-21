defprotocol JaSerializer.Formatter do
  @fallback_to_any true
  def format(data)
end

defimpl JaSerializer.Formatter, for: Any do
  def format(data), do: data
end

defimpl JaSerializer.Formatter, for: List do
  def format(list), do: Enum.map(list, &JaSerializer.Formatter.format/1)
end
