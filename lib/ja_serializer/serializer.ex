defmodule JaSerializer.Serializer do
  @moduledoc """
  Define a serialization schema.

  Provides `has_many/2`, `has_one/2`, `attributes/1` and `location/1` macros
  to define how your data (struct or map) will be rendered in the
  JSONAPI.org 1.0 format.

  Defines `format/1`, `format/2` and `format/3` used to convert data for
  encoding in your JSON library of choice.

  ## Example

      defmodule PostSerializer do
        use JaSerializer

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

  """

  use Behaviour

  @type id :: String.t | Integer
  @type data :: Map

  @doc """
  The id to be used in the resource object.

  http://jsonapi.org/format/#document-resource-objects

  Default implementation attempts to get the :id field from the struct.

  To override simply define the id function:

      def id(struct, _conn), do: struct.slug
  """
  defcallback id(data, Plug.Conn.t) :: id

  @doc """
  The type to be used in the resource object.

  http://jsonapi.org/format/#document-resource-objects

  Default implementation attempts to infer the type from the serializer
  module's name. For example:

      MyApp.UserView becomes "user"
      MyApp.V1.Serializers.Post becomes "post"
      MyApp.V1.CommentsSerializer becomes "comments"

  To override simply define the type function:

      def type, do: "category"
  """
  defcallback type() :: String.t

  @doc """
  Returns a map of attributes to be mapped.

  The default implementation relies on the `attributes/1` macro to define
  which fields to be included in the map.

      defmodule UserSerializer do
        attributes [:email, :name, :is_admin]
      end

      UserSerializer.attributes(user, conn)
      # %{email: "...", name: "...", is_admin: "..."}

  You may override this method and use `super` to filter attributes:

      defmodule UserSerializer do
        attributes [:email, :name, :is_admin]

        def attributes(user, conn) do
          attrs = super(user, conn)
          if conn.assigns[:current_user].is_admin do
            attrs
          else
            Map.take(attrs, [:email, :name])
          end
        end
      end

      UserSerializer.attributes(user, conn)
      # %{email: "...", name: "..."}

  You may also skip using the `attributes/1` macro altogether in favor of
  just defining `attributes/2`.

      defmodule UserSerializer do
        def attributes(user, conn) do
          Map.take(user, [:email, :name])
        end
      end

      UserSerializer.attributes(user, conn)
      # %{email: "...", name: "..."}

  """
  defcallback attributes(map, Plug.Conn.t) :: map

  @doc """
  Adds meta data to the individual resource being serialized.

  NOTE: To add meta data to the top level object pass the `meta:` option into
  YourSerializer.format/3.

  A nil return value results in no meta key being added to the serializer.
  A map return value will be formated with JaSerializer.Formatter.format/1.

  The default implementation returns nil.
  """
  defcallback meta(map, Plug.Conn.t) :: map | nil

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour JaSerializer.Serializer
      @attributes []
      @relations  []
      @location   nil

      import JaSerializer.Serializer, only: [
        serialize: 2, attributes: 1, location: 1,
        has_many: 2, has_one: 2, has_many: 1, has_one: 1
      ]

      unquote(define_default_type(__CALLER__.module))
      unquote(define_default_id)
      unquote(define_default_attributes)
      unquote(define_default_meta)

      @before_compile JaSerializer.Serializer
    end
  end

  defp define_default_type(module) do
    type = module
            |> Atom.to_string
            |> String.split(".")
            |> List.last
            |> String.replace("Serializer", "")
            |> String.replace("View", "")
            |> JaSerializer.Formatter.Utils.format_type
    quote do
      def type, do: unquote(type)
      defoverridable [type: 0]
    end
  end

  defp define_default_id do
    quote do
      def id(m),    do: Map.get(m, :id)
      def id(m, _c), do: apply(__MODULE__, :id, [m])
      defoverridable [{:id, 2}, {:id, 1}]
    end
  end

  defp define_default_attributes do
    quote do
      def attributes(struct, conn) do
        JaSerializer.Serializer.default_attributes(__MODULE__, struct, conn)
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

  defp define_default_meta do
    quote do
      def meta(_struct, _conn), do: nil
      defoverridable [meta: 2]
    end
  end

  @doc false
  defmacro serialize(type, do: block) do
    IO.write :stderr, IO.ANSI.format([:red, :bright,
      "warning: serialize/2 is deprecated, please use type/0 instead\n" <>
      Exception.format_stacktrace(Macro.Env.stacktrace(__CALLER__))
    ])

    quote do
      unquote(block)
      def type, do: unquote(type)
    end
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

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def __relations,  do: @relations
      def __location,   do: @location
      def __attributes, do: @attributes

      def format(data) do
        format(data, %{})
      end

      def format(data, conn) do
        format(data, conn, [])
      end

      def format(data, conn, opts) do
        %{data: data, conn: conn, serializer: __MODULE__, opts: opts}
        |> JaSerializer.Builder.build
        |> JaSerializer.Formatter.format
      end
    end
  end
end
