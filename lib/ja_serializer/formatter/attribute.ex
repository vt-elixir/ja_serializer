defimpl JaSerializer.Formatter, for: JaSerializer.Builder.Attribute do
  alias JaSerializer.Formatter.Utils

  def format(attr) do
    {Utils.dasherize(attr.key), JaSerializer.Formatter.format(attr.value)}
  end
end
