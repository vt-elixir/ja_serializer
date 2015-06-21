defimpl JaSerializer.Formatter, for: JaSerializer.Builder.TopLevel do
  alias JaSerializer.Formatter.Utils

  def format(struct) do
    %{jsonapi: %{version: "1.0"}}
    |> Map.put(:data, JaSerializer.Formatter.format(struct.data))
    |> Utils.put_if_present(:included, JaSerializer.Formatter.format(struct.included))
  end
end
