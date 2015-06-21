defimpl JaSerializer.Formatter, for: JaSerializer.Builder.Link do
  alias JaSerializer.Formatter.Utils

  def format(link) do
    {Utils.dasherize(link.type), link.href}
  end
end
