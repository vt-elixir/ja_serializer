defmodule JaSerializer.Builder do
  @moduledoc false

  def build(context) do
    JaSerializer.Builder.TopLevel.build(context)
  end
end
