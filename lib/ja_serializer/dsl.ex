defmodule JaSerializer.DSL do
  @doc false
  defmacro __using__(_) do
    quote do
      @attributes []
      @relations  []
      @type_key   nil

      import JaSerializer.DSL, only: [serialize: 2]

      @before_compile JaSerializer.DSL
    end
  end

  @doc """
  Define a serializer. The binary argument "type" should be the plural version
  of the type of object being serialized.
  """
  defmacro serialize(type, do: block) do
    quote do
      import JaSerializer.DSL, only: [
        attributes: 1, has_many: 2, has_many: 1, has_one: 2, has_one: 1
      ]

      @type_key unquote(type)
      unquote(block)
    end
  end

  @doc """

  TODO
  """
  defmacro attributes(atts) do
    quote bind_quoted: [atts: atts] do
      # Save attributes
      @attributes @attributes ++ atts

      # Define default attribute function, make overridable
      for att <- atts do
        def unquote(att)(m),    do: Map.get(m, unquote(att))
        def unquote(att)(m, c), do: apply(__MODULE__, unquote(att), [m])
        defoverridable [{att, 2}, {att, 1}]
      end
    end
  end

  @doc """

  Adds a serialized relationship. By default expects to include a list of ids
  in the serialized resource. Include the full resource in the output by
  included a serializer option.

  Override the default by defining a function of relation name with arity of 2.

  ## Opts

  * field - The field to call on the model to get a list of ids. Defaults to
            the relation name.
  * serializer - If defined full representation is expected in response. Should
                 be a module name.
  * link - Represent this resource as a link to another resource.

  """
  defmacro has_many(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      @relations [{:has_many, name, opts} | @relations]
      # Define default relation function, make overridable
      def unquote(name)(m, c), do: apply(__MODULE__, unquote(name), [m])
      def unquote(name)(model) do
        Map.get(model, (unquote(opts)[:field] || unquote(name)))
      end
      defoverridable [{name, 2}, {name, 1}]
    end
  end

  defmacro has_one(name, opts \\ []) do
    #TODO: Dry up setting up relationships.
    quote bind_quoted: [name: name, opts: opts] do
      @relations [{:has_one, name, opts} | @relations]
      # Define default relation function, make overridable
      def unquote(name)(m, c), do: apply(__MODULE__, unquote(name), [m])
      def unquote(name)(model) do
        Map.get(model, (unquote(opts)[:field] || unquote(name)))
      end
      defoverridable [{name, 2}, {name, 1}]
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def __attributes, do: @attributes
      def __type_key,   do: @type_key
      def __relations,  do: @relations

      def format(model) do
        model
      end
    end
  end
end
