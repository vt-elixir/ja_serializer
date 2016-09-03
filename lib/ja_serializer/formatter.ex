defprotocol JaSerializer.Formatter do
  @dialyzer {:nowarn_function, __protocol__: 1}
  @fallback_to_any true
  def format(data)
end

defimpl JaSerializer.Formatter, for: Any do
  def format(data), do: data
end

defimpl JaSerializer.Formatter, for: List do
  def format(list), do: Enum.map(list, &JaSerializer.Formatter.format/1)
end

# Pass built in data types through
defimpl JaSerializer.Formatter, for: [BitString, Integer, Float, Atom, Function, PID, Port, Reference, Tuple] do
  def format(data), do: data
end

defimpl JaSerializer.Formatter, for: [Ecto.DateTime, Ecto.Time, Ecto.Date] do
  def format(data), do: data
end

defimpl JaSerializer.Formatter, for: [Decimal] do
  def format(data), do: data
end
