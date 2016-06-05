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
  @type data :: map

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

  You may also specify a dynamic type which recieves the data
  and connection as parameters:

      def type, do: fn(model, _conn) -> model.type end
  """
  defcallback type() :: String.t | fun()

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

  @doc """
  return relationship structs
  """
  defcallback relationships(map, Plug.Conn.t) :: map

  @doc """
  return links about this resource
  """
  defcallback links(map, Plug.Conn.t) :: map

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour JaSerializer.Serializer
      alias JaSerializer.Relationship.HasMany
      alias JaSerializer.Relationship.HasOne

      # Default Behaviour Callback Defintions
      unquote(define_default_id)
      unquote(define_default_type(__CALLER__.module))
      unquote(define_default_meta)
      unquote(define_default_links)
      unquote(define_default_attributes)
      unquote(define_default_relationships)

      # API to call into serialization
      unquote(define_api)
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
      def id(data, _c), do: Map.get(data, :id)
      defoverridable [id: 2]
    end
  end

  defp define_default_meta do
    quote do
      def meta(_struct, _conn), do: nil
      defoverridable [meta: 2]
    end
  end

  defp define_default_links do
    quote do
      def links(_struct, _conn), do: %{}
      defoverridable [links: 2]
    end
  end

  defp define_default_attributes do
    quote do
      def attributes(data, _conn), do: Map.drop(data, [:id, :type, :__struct__])
      defoverridable [attributes: 2]
    end
  end

  defp define_default_relationships do
    quote do
      def relationships(_struct, _conn), do: %{}
      defoverridable [relationships: 2]
    end
  end

  defp define_api do
    quote do
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
