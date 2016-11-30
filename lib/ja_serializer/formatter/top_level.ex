defimpl JaSerializer.Formatter, for: JaSerializer.Builder.TopLevel do
  alias JaSerializer.Formatter.Utils

  @jsonapi_version "1.0"

  def format(struct = %{errors: nil}) do
    %{"data" =>  JaSerializer.Formatter.format(struct.data)}
    |> format_links(struct.links)
    |> Utils.put_if_present("meta", JaSerializer.Formatter.format(struct.meta))
    |> Utils.put_if_present("included", JaSerializer.Formatter.format(struct.included))
    |> put_version
  end

  def format(struct = %{data: nil}) do
    %{"errors" =>  JaSerializer.Formatter.format(struct.errors)} |> put_version
  end

  defp format_links(resource, nil), do: resource
  defp format_links(resource, []), do: resource
  defp format_links(resource, links) do
    links = links
            |> JaSerializer.Formatter.format
            |> Enum.reject(&(is_nil(&1)))
            |> Enum.into(%{})
    Map.put(resource, "links", links)
  end

  defp put_version(resource) do
    resource |> Map.put("jsonapi", %{"version" => @jsonapi_version})
  end
end
