defimpl JaSerializer.Formatter, for: JaSerializer.Builder.Attribute do
  alias JaSerializer.Formatter.Utils

  def format(attr) do
    {Utils.format_key(attr.key), JaSerializer.Formatter.format(attr.value)}
  end
end
