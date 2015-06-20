defmodule JaSerializer.Builder do
  @doc """
  Build up a representation of the resource in the internal jsonapi.org
  data structure.
  """
  def build(context) do
    JaSerializer.Builder.TopLevel.build(context)
  end

  defmodule JSONAPIDocument do
    defstruct [version: "1.0"]
  end
end
