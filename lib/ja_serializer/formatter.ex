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

defimpl JaSerializer.Formatter, for: [BitString, Integer, Float, Atom] do
  def format(data), do: data
end

defimpl JaSerializer.Formatter, for: [Ecto.DateTime, Ecto.Time, Ecto.Date] do
  def format(dt), do: dt
end

defimpl JaSerializer.Formatter, for: [Decimal] do
  def format(dt), do: dt
end
