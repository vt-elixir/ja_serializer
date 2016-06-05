defmodule JaSerializer.DSL do
  alias JaSerializer.Relationship.HasMany
  alias JaSerializer.Relationship.HasOne

  defmacro __using__(_) do
    quote do
      @attributes []
      @relations  []
      @location   nil

      import JaSerializer.DSL, only: [
        attributes: 1, location: 1,
        has_many: 2, has_one: 2, has_many: 1, has_one: 1
      ]

      unquote(define_default_attributes)
      unquote(define_default_relationships)
      unquote(define_default_links)

      @before_compile JaSerializer.DSL
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def __relations,  do: @relations
      def __location,   do: @location
      def __attributes, do: @attributes
    end
  end

  defp define_default_attributes do
    quote do
      def attributes(struct, conn) do
        JaSerializer.DSL.default_attributes(__MODULE__, struct, conn)
      end
      defoverridable [attributes: 2]
    end
  end

  @doc false
  def default_attributes(serializer, struct, conn) do
    serializer.__attributes
    |> Enum.map(&({&1, apply(serializer, &1, [struct, conn])}))
    |> Enum.into(%{})
  end

  defp define_default_relationships do
    quote do
      def relationships(struct, conn) do
        JaSerializer.DSL.default_relationships(__MODULE__, struct, conn)
      end
      defoverridable [relationships: 2]
    end
  end

  @doc false
  def default_relationships(serializer, struct, conn) do
    serializer.__relations
    |> Enum.map(&dsl_to_struct/1)
    |> Enum.into(%{})
  end

  defp dsl_to_struct({:has_one, name, opts}),
    do: {name, HasOne.from_dsl(name, opts)}
  defp dsl_to_struct({:has_many, name, opts}),
    do: {name, HasMany.from_dsl(name, opts)}

  defp define_default_links do
    quote do
      def links(data, conn) do
        JaSerializer.DSL.default_links(__MODULE__, data, conn)
      end
      defoverridable [links: 2]
    end
  end

  @doc false
  def default_links(serializer, data, conn) do
    %{self: serializer.__location}
  end

  @doc """
  Defines the canonical path for retrieving this resource.

  ## String Examples

  String may be either a relative or absolute path. Path segments beginning
  with a colon are called as functions on the serializer with the struct and
  conn passed in.

      defmodule PostSerializer do
        use JaSerializer

        location "/posts/:id"
      end

      defmodule CommentSerializer do
        use JaSerializer

        location "http://api.example.com/posts/:post_id/comments/:id"

        def post_id(comment, _conn), do: comment.post_id
      end

  ## Atom Example

  When an atom is passed in it is assumed it is a function that will return
  a relative or absolute path.

      defmodule PostSerializer do
        use JaSerializer
        import MyPhoenixApp.Router.Helpers

        location :post_url

        def post_url(post, conn) do
          #TODO: Verify conn can be used here instead of Endpoint
          post_path(conn, :show, post.id)
        end
      end

  """
  defmacro location(uri) do
    quote bind_quoted: [uri: uri] do
      @location uri
    end
  end

  @doc """
  Defines a list of attributes to be included in the payload.

  An overridable function for each attribute is generated with the same name
  as the attribute. The function's default behavior is to retrieve a field with
  the same name from the struct.

  For example, if you have `attributes [:body]` a function `body/2` is defined
  on the serializer with a default behavior of `Map.get(struct, :body)`.
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
  Add a has_many relationship to be serialized.

  Relationships may be included in any of three composeable ways:

  * Links
  * Resource Identifiers
  * Includes

  ## Relationship Source

  When you define a relationship, a function is defined of the same name in the
  serializer module. This function is overrideable but by default attempts to
  access a field of the same name as the relationship on the map/struct passed
  in. The field may be changed using the `field` option.

  For example if you `have_many :comments` a function `comments\2` is defined
  which calls `Dict.get(struct, :comments)` by default.

  ## Link based relationships

  Specify a uri which responds with the related resources.
  See <a href='#location/1'>location/1</a> for defining uris.

  The relationship source is disregarded when linking.

      defmodule PostSerializer do
        use JaSerializer

        has_many :comments, links: [related: "/posts/:id/comments"]
      end

  ## Resource Identifier Relationships

  Adds a list of `id` and `type` pairs to the response with the assumption the
  API consumer can use them to retrieve the related resources as needed.

  The relationship source should return either a list of ids or maps/structs
  that have an `id` field.

      defmodule PostSerializer do
        use JaSerializer

        has_many :comments, type: "comments"

        def comments(post, _conn) do
          post |> Post.get_comments |> Enum.map(&(&1.id))
        end
      end

  ## Included Relationships

  Adds a list of `id` and `type` pairs, just like Resource Identifier
  relationships, but also adds the full serialized resource to the response to
  be "sideloaded" as well.

  The relationship source should return a list of maps/structs.

      defmodule PostSerializer do
        use JaSerializer

        has_many :comments, serializer: CommentSerializer, include: true

        def comments(post, _conn) do
          post |> Post.get_comments
        end
      end

      defmodule CommentSerializer do
        use JaSerializer

        has_one :post, field: :post_id, type: "posts"
        attributes [:body]
      end

  """
  defmacro has_many(name, opts \\ []) do
    normalized_opts = normalize_relation_opts(opts, __CALLER__)

    quote do
      @relations [{:has_many, unquote(name), unquote(normalized_opts)} | @relations]
      unquote(JaSerializer.Relationship.default_function(name, normalized_opts))
    end
  end

  @doc """
  See documentation for <a href='#has_many/2'>has_many/2</a>.

  API is the exact same.
  """
  defmacro has_one(name, opts \\ []) do
    normalized_opts = normalize_relation_opts(opts, __CALLER__)

    quote do
      @relations [{:has_one, unquote(name), unquote(normalized_opts)} | @relations]
      unquote(JaSerializer.Relationship.default_function(name, normalized_opts))
    end
  end

  defp normalize_relation_opts(opts, caller) do
    include = opts[:include]

    if opts[:field] && !opts[:type] do
      IO.write :stderr, IO.ANSI.format([:red, :bright,
        "warning: The `field` option must be used with a `type` option\n" <>
        Exception.format_stacktrace(Macro.Env.stacktrace(caller))
      ])
    end

    if opts[:link] do
      updated =
        Keyword.get(opts, :links, [])
          |> Keyword.put_new(:related, opts[:link])

      opts = Keyword.put(opts, :links, updated)
    end

    case is_boolean(include) or is_nil(include) do
      true -> opts
      false ->
        IO.write :stderr, IO.ANSI.format([:red, :bright,
          "warning: Specifying a non-boolean as the `include` option is " <>
          "deprecated. If you are specifying the serializer for this " <>
          "relation, use the `serializer` option instead. To always " <>
          "side-load the relationship, use `include: true` in addition to " <>
          "the `serializer` option\n" <>
          Exception.format_stacktrace(Macro.Env.stacktrace(caller))
        ])

        [serializer: include, include: true] ++ opts
    end
  end

end
