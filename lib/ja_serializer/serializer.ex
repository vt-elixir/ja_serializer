defmodule JaSerializer.Serializer do
  @moduledoc """
  Define a serialization schema.

  Provides `serialize/2`, `has_many/2`, `has_one/2`, `attributes\1` and
  `location\1` macros to define how your model (struct or map) will be rendered
  in the JSONAPI.org 1.0 format.

  Defines `format/1`, `format/2` and `format/3` used to convert models (and
  list of models) for encoding in your JSON library of choice.

  ## Example

      defmodule PostSerializer do
        use JaSerializer

        serialize "posts" do
          location "/posts/:id"
          attributes [:title, :body, :excerpt, :tags]
          has_many :comments,
            link: "/posts/:id/comments",
          has_one :author,
            include: PersonSerializer
        end

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

  @doc false
  defmacro __using__(_) do
    quote do
      @attributes []
      @relations  []
      @type_key   nil
      @location   nil

      import JaSerializer.Serializer, only: [serialize: 2]

      @before_compile JaSerializer.Serializer
    end
  end

  @doc """
  Define a serialization schema.

  The `type` should be the plural version of the type of object being
  serialized. This maps to the JSONAPI type field.

  Defines an overridable `id` function that is expected to return the id of the
  object being serialized. Defaults to `Map.get(model, :id)`.

  ## Example

      defmodule PostSerializer do
        use JaSerializer

        serialize "posts" do
          # JaSerializer.Serialization macros available here.
        end

        # Optional override
        def id(post, conn) do
          post.id
        end
      end

  """
  defmacro serialize(type, do: block) do
    quote do
      import JaSerializer.Serializer, only: [
        attributes: 1, has_many: 2, has_many: 1, has_one: 2, has_one: 1,
        location: 1
      ]

      @type_key unquote(type)
      unquote(block)

      def id(m),    do: Map.get(m, :id)
      def id(m, c), do: apply(__MODULE__, :id, [m])
      defoverridable [{:id, 2}, {:id, 1}]
    end
  end

  @doc """
  Defines the canoical path for retrieving this resource.

  ## String Examples

  String may be either a full url or a relative path. Path segments begining
  with a colin are called as functions on the serializer with the model and
  conn passed in.

      defmodule PostSerializer do
        use JaSerializer

        serialize "posts" do
          location "/posts/:id"
        end
      end

      defmodule CommentSerializer do
        use JaSerializer

        serialize "comment" do
          location "http://api.example.com/posts/:post_id/comments/:id"
        end

        def post_id(comment, _conn), do: comment.post_id
      end

  ## Atom Example

  When an atom is passed in it is assumed it is a function that will return
  a relative or absolute path.

      defmodule PostSerializer do
        use JaSerializer
        import MyPhoenixApp.Router.Helpers

        serialize "post" do
          location :post_url
        end

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

  An overrideable function for each attribute is generated with the same name
  as the attribute. The function's default behavior is to retrieve a field with
  the same name from the model.

  For example, if you have `attributes [:body]` a function `body/2` is defined
  on the serializer with a default behavior of `Map.get(model, :body)`.
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
  which calls `Dict.get(model, :comments)` by default.

  ## Link based relationships

  Specify a uri which responds with the related resources.
  See <a href='#location/1'>location/1</a> for defining uris.

  The relationship source is disregarded when linking.

      defmodule PostSerializer do
        use JaSerializer

        serialize "posts" do
          has_many :comments, link: "/posts/:id/comments"
        end
      end

  ## Resource Identifier Relationships

  Adds a list of `id` and `type` pairs to the response with the assumption the
  API consumer can use them to retrieve the related resources as needed.

  The relationship source should return either a list of ids or maps/structs
  that have an `id` field.

      defmodule PostSerializer do
        use JaSerializer

        serialize "posts" do
          has_many :comments, type: "comments"
        end

        def comments(post, _conn) do
          post |> PostModel.get_comments |> Enum.map(&(&1.id))
        end
      end

  ## Included Relationships

  Adds a list of `id` and `type` pairs, just like Resource Indentifier
  relationships, but also adds the full serialized resource to the response to
  be "sideloaded" as well.

  The relationship source should return a list of maps/structs.

  *WARNING: Currently sideloaded resources do not have thier own included
  resources included.*

      defmodule PostSerializer do
        use JaSerializer

        serialize "posts" do
          has_many :comments, include: CommentSerializer
        end

        def comments(post, _conn) do
          post |> PostModel.get_comments
        end
      end

      defmodule CommentSerializer do
        use JaSerializer

        serialize "comments" do
          has_one :post, field: :post_id, type: "posts"
          attributes [:body]
        end
      end

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

  @doc """
  See documentation for <a href='#has_many/2'>has_many/2</a>.

  API is the exact same.
  """
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
      def __location,   do: @location

      def format(model) do
        format(model, %{})
      end

      def format(model, conn) do
        format(model, conn, [])
      end

      def format(model, conn, opts) do
        %{model: model, conn: conn, serializer: __MODULE__, opts: opts}
        |> JaSerializer.Builder.build
        |> JaSerializer.Formatter.format
      end
    end
  end
end
