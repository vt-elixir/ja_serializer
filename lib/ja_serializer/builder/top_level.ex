defmodule JaSerializer.Builder.TopLevel do
  alias JaSerializer.Builder.ResourceObject
  alias JaSerializer.Builder.JSONAPIDocument
  alias JaSerializer.Builder.Included

  defstruct [:data, :errors, :included, :meta, :links, :jsonapi]

  def build(context) do
    %__MODULE__{}
    |> Map.put(:jsonapi, %JSONAPIDocument{})
    |> Map.put(:data, ResourceObject.build(context))
    |> Map.put(:included, Included.build(context))
    |> add_meta(context)
    |> add_links(context)
  end

  #TODO: Add includes, meta and links
  def add_meta(tl, _context), do: tl
  def add_links(tl, _context), do: tl
end
