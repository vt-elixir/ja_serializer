defmodule JaSerializer.DSL do
  @moduledoc """
  A DSL for defining JSON-API.org spec compliant payloads.

  Built on top of the `JaSerializer.Serializer` behaviour.

  The following macros are available:

    * `location/1` - Define the url of a single serialized object.
    * `attributes/1` - Define the attributes to be returned.
    * `has_many/2` - Define a has_many relationship.
    * `has_one/2` - Define a has_one or belongs_to relationship.

  This module should always be used in conjunction with
  `JaSerializer.Serializer`, see `JaSerializer` for the best way to do so.

  ## DSL Usage Example

      defmodule PostSerializer do
        use JaSerializer, dsl: true

        location "/posts/:id"
        attributes [:title, :body, :excerpt, :tags]
        has_many :comments, links: [related: "/posts/:id/comments"]
        has_one :author, serializer: PersonSerializer, include: true

        def excerpt(post, _conn) do
          [first | _ ] = String.split(post.body, ".")
          first
        end
      end

      post = %Post{
        id: 1,
        title: "jsonapi.org + Elixir = Awesome APIs",
        body: "so. much. awesome.",
        author: %Person{name: "Alan"}
      }

      post
      |> PostSerializer.format
      |> Poison.encode!

  When `use`ing JaSerializer.DSL the default implementations of the `links/2`,
  `attributes/2`, and `relationships/2` callbacks will be defined on your module.

  Overriding these callbacks can be a great way to customize your serializer
  beyond what the DSL provides. See `JaSerializer.Serializer` for examples.
  """

  alias JaSerializer.Relationship.HasMany
  alias JaSerializer.Relationship.HasOne

  @doc false
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
      def relationships(struct, _conn) do
        JaSerializer.DSL.default_relationships(__MODULE__)
      end
      defoverridable [relationships: 2]
    end
  end

  @doc false
  def default_relationships(serializer) do
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
        JaSerializer.DSL.default_links(__MODULE__)
      end
      defoverridable [links: 2]
    end
  end

  @doc false
  def default_links(serializer) do
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

  When an atom is passed in, it is called as a function on the serializer with
  the struct and conn passed in. The function should return a full path/url.

      defmodule PostSerializer do
        use JaSerializer
        import MyPhoenixApp.Router.Helpers

        location :post_url

        def post_url(post, conn) do
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
  Defines a list of attributes as atoms to be included in the payload.

  An overridable function for each attribute is generated with the same name
  as the attribute. The function's default behavior is to retrieve a field with
  the same name from the struct.

  For example, if you have `attributes [:body]` a function `body/2` is defined
  on the serializer with a default behavior of `Map.get(struct, :body)`.

      defmodule PostSerializer do
        use JaSerializer, dsl: true
        attributes [:title, :body, :html]

        def html(post, _conn) do
          Earmark.to_html(post.body)
        end
      end

  ## Conditional attribute inclusion

  JaSerializer supports the `fields` option as per the JSONAPI spec. This
  option allows clients to request only the fields they want. For example if
  you only wanted the html and the title for the post:

      field_param = %{"post" => "title,html", "comment" => "html"}

      # Direct Serialization
      PostSerializer.format(post, conn, fields: field_param)

      # via PhoenixView integrations from controller
      render(conn, :show, data: post, opts: [fields: field_param])

  ## Further customization

  Further customization of the attributes returned can be handled by overriding
  the `attributes/2` callback. This can be done in conjunction with the DSL
  using super, or without the DSL just returning a map.

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

  JSONAPI.org supports three types or relationships:

    * As links - Great for clients lazy loading relationships with lots of data.
    * As "Resource Indentifiers" - A type/id pair, useful to relate to data the client already has.
    * As Included Resources - The full resource is serialized in the same request (also includes Resource Identifiers).

  Links can be combined with either resource identifiers or fully included resources.

  See http://jsonapi.org/format/#document-resource-object-relationships for more
  details on the spec.

  ## Link based relationships

  Specify a URI or path which responds with the related resource. For example:

      defmodule MyApp.PostView do
        use JaSerializer

        has_many :comments, link: :comments_link
        has_one  :author, link: "/api/posts/:id/author"

        def comments_link(post, conn) do
          MyApp.Router.Helpers.post_comment_url(conn, :index, post.id)
        end
      end

  Links can be defined with an atom or string.

  String may be either a relative or absolute path. Path segments beginning
  with a colon are called as functions on the serializer with the struct and
  conn passed in. In the above example id/2 would be called which is defined as
  a default callback.

  When an atom is passed in, it is called as a function on the serializer with
  the struct and conn passed in. The function should return a full path/url.

  Both `related` and `self` links are supported, the default `link` creates a
  related link:

      defmodule PostSerializer do
        use JaSerializer

        has_many :comments, links: [
          related: "/posts/:id/comments"
          self: "/posts/:id/relationships/comments"
        ]
      end

  ## Resource Identifiers (without including)

  Return id and type for each related object ("Resource Identifier"). For example:

      defmodule MyApp.PostView do
        use JaSerializer

        has_many :comments, serializer: MyApp.CommentView, include: false
        has_many :tags, type: "tags"
        has_one  :author, type: "user", field: :created_by_id

        # ...
      end

  When you use the `has_many` and `has_one` macros an overridable "data source"
  function is defined on your module. The data source fuction has the same name
  as the relationship name and accepts the struct and conn. The data source
  function should return the related struct(s) or id(s). In the example above
  the following functions are defined for you:

      def comments(post, _conn), do: Map.get(post, :comments)
      def tags(post, _conn),     do: Map.get(post, :tags)
      def author(post, _conn),   do: Map.get(post, :created_by_id)

  These data source functions are expected to return either related objects or
  ids, by default they just access the field with the same name as the
  relationship. The `field` option can be used to grab the id or struct from a
  different field in the serialized object. The author is an example of
  customizing this, and is frequently used when returning resource identifiers
  for has_one relationships when you have the foreign key in the serialized
  struct.

  In the comments example when a `serializer` plus `include: false` options are
  used the `id/2` and `type/2` functions are called on the defined serializer.

  In the tags example where just the `type` option is used the `id` field is
  automatically used on each map/struct returned by the data source.

  It is important to note that when accessing the relationship fields it is
  expected that the relationship is preloaded. For this reason you may want to
  consider using links for has_many relationships where possible.

  ## Including related data

  Returns a "Resource Identifier" (see above) as well as the fully serialized
  object in the top level `included` key. Example:

      defmodule MyApp.PostView do
        use JaSerializer

        has_many :comments, serializer: MyApp.CommentView, include: true, identifiers: :when_included
        has_many :tags,     serializer: MyApp.TagView,     include: true, identifiers: :always
        has_many :author,   serializer: MyApp.AuthorView,  include: true, field: :created_by

        # ...
      end

  Just like when working with only Resource Identifiers this will define a
  'data source' function for each relationship with an arity of two. They will
  be overridable and are expected to return maps/structs.

  ## Conditional Inclusion

  JaSerializer supports the `include` option as per the JSONAPI spec. This
  option allows clients to include only the relationships they want.
  JaSerializer handles the serialization of this for you, however you will have
  to handle intellegent preloading of relationships yourself.

  When a relationship is not loaded via includes the `identifiers` option will
  be used to determine if Resorce Identifiers should be serialized or not. The
  `identifiers` options accepts the atoms `:when_included` and `:always`.

  When specifying the include param, only the relationship requested will be
  included. For example, to only include the author and comments:

      include_param = "author,comments"

      # Direct Serialization
      PostSerializer.format(post, conn, include: include_param)

      # via PhoenixView integrations from controller
      render(conn, :show, data: post, opts: [include: include_param])

  ## Further Customization

  For further customization override the `relationships/2` callback directly.

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

    opts = if opts[:link] do
      updated = opts
        |> Keyword.get(:links, [])
        |> Keyword.put_new(:related, opts[:link])

      Keyword.put(opts, :links, updated)
    else
      opts
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
