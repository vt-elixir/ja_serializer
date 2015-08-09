defmodule JaSerializer.Builder.Attribute do
  @moduledoc false

  defstruct [:key, :value]

  def build(%{model: model, serializer: serializer, conn: conn}) do
    Enum.map apply(serializer,:attributes, [model, conn]), &do_build/1
  end

  def do_build({key, value}), do: %__MODULE__{key: key, value: value}
end
