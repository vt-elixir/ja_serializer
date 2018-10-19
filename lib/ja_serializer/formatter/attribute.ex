defimpl JaSerializer.Formatter, for: JaSerializer.Builder.Attribute do
  alias JaSerializer.Formatter.Utils

  def format(attr) do
    cond do
      is_list(attr.value) ->
        values = Utils.deep_format_keys(attr.value)
        {Utils.format_key(attr.key), JaSerializer.Formatter.format(values)}

      is_map(attr.value) ->
        values = Utils.deep_format_keys(attr.value)
        {Utils.format_key(attr.key), JaSerializer.Formatter.format(values)}

      true ->
        {Utils.format_key(attr.key), JaSerializer.Formatter.format(attr.value)}
    end
  end
end
