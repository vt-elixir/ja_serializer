defmodule JaSerializer.Serializer do
  @moduledoc """
  A Behaviour for defining JSON-API.org spec complaint payloads.

  The following callbacks are available:

    * `id/2` - Return ID of struct to be serialized.
    * `type/2` - Return string type of struct to be serialized.
    * `attributes/2` - A map of attributes to be serialized.
    * `relationships/2`- A map of `HasMany` and `HasOne` data structures.
    * `links/2` - A keyword list of any links pertaining to this struct.
    * `meta/2` - A map of any additional meta information to be serialized.
    * `preload/3` - A special callback that can be used to preload related data.

  A Serializer (or view) is typically one of the few places in an API where
  content and context are both present. To accomodate this each callback gets
  the data being serialized (typically a struct, often called a model) and the
  Plug.Conn as arguments. Context data such as the current user, role, etc
  should typically be made available on the conn.

  When `use`ing this module all callbacks get a default, overridable
  implementation. The `JaSerializer.DSL` module also provides some default
  implementations of these callbacks built up from the DSL. When using the DSL
  overriding the Behaviour functions can be a great way to customize
  conditional logic.

  While not typically used directly, the interface for returning formatted data
  is also defined. The results still need to be encoded into JSON as appropriate.

      defmodule FooSerializer do
        use JaSerializer
      end

      # Format one foo
      FooSerializer.format(one_foo, conn, meta)

      # Format many foos
      FooSerializer.format(many_foos, conn, meta)

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

      def type(_post,_conn), do: "category"
  """
  defcallback type(map, Plug.Conn.t) :: String.t

  @doc """
  Returns a map of attributes to be serialized.

  The default implementation returns all the data's fields except `id`, `type`,
  and `__struct__`.

  A typical non-DSL implementation looks like:

      defmodule UserSerializer do
        def attributes(user, conn) do
          Map.take(user, [:email, :name])
        end
      end

      UserSerializer.attributes(user, conn)
      # %{email: "...", name: "..."}

  If using the `JaSerializer.DSL` the default implementation is based on the
  `JaSerializer.DSL.attributes/1` macro. Eg:

      defmodule UserSerializer do
        attributes [:email, :name, :is_admin]
      end

      UserSerializer.attributes(user, conn)
      # %{email: "...", name: "...", is_admin: "..."}

  Overriding this callback can be a good way to customize attribute behaviour
  based on the context (conn) with super.

      defmodule UserSerializer do
        attributes [:email, :name, :is_admin]

        def attributes(user, %{assigns: %{current_user: %{is_admin: true}}}) do
          super(user, conn)
        end

        def attributes(user, conn) do
          super(user, conn)
          |> Map.take([:email, :name])
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
  A callback that should return a map of relationship structs.

  Example:

      def relationships(article, _conn) do
        %{
          comments: %HasMany{
            serializer:  MyApp.CommentView,
            include:     true,
            data:        article.comments,
          },
          author: %HasOne{
            serializer:  MyApp.AuthorView,
            include:     true,
            data:        article.author,
          }
        }
      end

  See JaSerializer.Relationship.HasMany for details on fields.

  When using the DSL this is defined for you based on the has_many and has_one
  macros.
  """
  defcallback relationships(map, Plug.Conn.t) :: map

  @doc """
  return links about this resource
  """
  defcallback links(map, Plug.Conn.t) :: map

  @doc """
  A special callback that can be used to preload related data.

  Unlike the other callbacks, this callback is ONLY executed on the top level
  data being serialized. Also unlike any other callback when serializing a list
  of data (eg: from an index action) it recieves the entire list, not each
  individual post. When serializing a single record (eg, show, create, update)
  a single record is received.

  The primary use case of the callback is to preload all the relationships you
  need. For example:

      @default_includes [:category, comments: :author]
      def preload(record_or_records, _conn, []) do
        MyApp.Repo.preload(record_or_records, @default_includes)
      end
      def preload(record_or_records, _conn, include_opts) do
        MyApp.Repo.preload(record_or_records, include_opts)
      end

  """
  defcallback preload(map | [map], Plug.Conn.t, nil | Keyword.t) :: map | [map]

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
      unquote(define_default_preload)

      # API to call into serialization
      unquote(define_api)
    end
  end

  defp define_default_type(module) do
    type_from_module = module
                        |> Atom.to_string
                        |> String.split(".")
                        |> List.last
                        |> String.replace("Serializer", "")
                        |> String.replace("View", "")
                        |> JaSerializer.Formatter.Utils.format_type
    quote do
      def type, do: unquote(type_from_module)
      def type(_data, _conn), do: type()
      defoverridable [type: 2, type: 0]
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

  defp define_default_preload do
    quote do
      def preload(data, _conn, _include_opts), do: data
      defoverridable [preload: 3]
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
        IO.write :stderr, IO.ANSI.format([:red, :bright,
          "warning: #{__MODULE__}.format/3 is deprecated.\n" <>
          "Please use JaSerializer.format/4 instead, eg:\n" <>
          "JaSerializer.format(#{__MODULE__}, data, conn, opts)\n"
        ])
        JaSerializer.format(__MODULE__, data, conn, opts)
      end
    end
  end
end
