defmodule JaSerializer do
  @moduledoc """
  A library for generating JSON-API.org spec compliant JSON.

  JaSerializer has three main public components:

    * `JaSerializer.Serializer` - A Behaviour defining how a particular object
      is serialized. Provides default empty callbacks and ability to override.

    * `JaSerializer.DSL` - A macro based DSL that sits on top of the Behaviour
      for quick, clean, and easy definition of serializers.

    * `JaSerializer.PhoenixView` - Provides render functions for a view to take
      advantage of the serialization interface.

  When used the `JaSerializer` module includes the Behaviour and DSL by default.
  The DSL can be opted out of by passing `dsl: false`, eg:

      defmodule MyApp.PostSerializer do
        use JaSerializer, dsl: false
        # ...
      end

  If using JaSerializer with Phoenix, your normal entry point is
  `JaSerializer.PhoenixView`, eg:

      defmodule MyApp.PostView do
        use MyApp.Web, :view
        use JaSerializer.PhoenixView
        # ...
      end

  """

  @doc false
  defmacro __using__(opts) do
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

  @doc """
  Main serialization method.

  Accepts a module implementing the JaSerializer.Serializer behaviour, data,
  the conn and opts and returns a map ready for json encoding.
  """
  def format(serializer, data, conn \\ %{}, opts \\ []) do
    %{data: data, conn: conn, serializer: serializer, opts: opts}
    |> JaSerializer.Builder.build
    |> JaSerializer.Formatter.format
  end
end
