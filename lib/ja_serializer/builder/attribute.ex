defmodule JaSerializer.Builder.Attribute do
  @moduledoc false

  defstruct [:key, :value]

  def build(%{model: model, serializer: serializer, conn: conn}) do
    Enum.map serializer.__attributes, fn(attr) ->
      %__MODULE__{
        key:   attr,
        value: apply(serializer, attr, [model, conn])
      }
    end
  end
end
