defimpl JaSerializer.Formatter, for: JaSerializer.Builder.Attribute do
  alias JaSerializer.Formatter.Utils

  def format(%{value: value, key: key}) when is_map(value) or is_list(value) do
    values = Utils.deep_format_keys(value)
    {Utils.format_key(key), JaSerializer.Formatter.format(values)}
  end

  def format(attr) do
    {Utils.format_key(attr.key), JaSerializer.Formatter.format(attr.value)}
  end
end
