defmodule JaSerializer.Builder.TopLevel do
  @moduledoc false

  alias JaSerializer.Builder.ResourceObject
  alias JaSerializer.Builder.Included

  defstruct [:data, :errors, :included, :meta, :links, :jsonapi]

  def build(context) do
    data = ResourceObject.build(context)
    %__MODULE__{}
    |> Map.put(:data, data)
    |> Map.put(:included, Included.build(context, data))
    |> add_meta(context)
    |> add_links(context)
  end

  #TODO Add links for pagination etc
  def add_links(tl, _context), do: tl

  #TODO: Add meta
  def add_meta(tl, _context), do: tl
end
