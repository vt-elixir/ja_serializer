defprotocol JaSerializer.Formatter do
  @fallback_to_any true

  def format(data)
end

defimpl JaSerializer.Formatter, for: Any do
  def format(data), do: data
end
