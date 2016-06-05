defmodule JaSerializer do
  @moduledoc """
  Provides a behaviour and optional DSL for defining and how to serialize data.

  The DSL can be opted out of by passing `dsl: false`, eg:

      defmodule MyApp.PostView do
        use JaSerializer, dsl: false
      end

  See JaSerializer.Serializer for details on the behaviour.

  See JaSerializer.DSL for details on the DSL.
  """

  defmacro __using__(opts \\ []) do
    # Default to using DSL for now.
    opts = Keyword.put_new(opts, :dsl, true)
    if opts[:dsl] do
      quote  do
        use JaSerializer.Serializer
        use JaSerializer.DSL
      end
    else
      quote do
        use JaSerializer.Serializer
      end
    end
  end
end
