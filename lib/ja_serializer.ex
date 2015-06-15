defmodule JaSerializer do
  @moduledoc """
  Provides a DSL for defining and how to serialize data to return in jsonapi.org 1.0 format.

  See JaSerializer.Map for default serializer use.
  """

  defmacro __using__(_) do
    quote do
      use JaSerializer.DSL
    end
  end
end
