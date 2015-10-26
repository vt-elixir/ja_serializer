defmodule JaSerializer.PhoenixView do

  @moduledoc """
  Use in your Phoenix view to render jsonapi.org spec json.

  See JaSerializer.Serializer for documentation on defining your serializer.

  ## Usage example

      defmodule PhoenixExample.ArticlesView do
        use PhoenixExample.Web, :view
        use JaSerializer.PhoenixView # Or use in web/web.ex

        attributes [:title]
      end

      defmodule PhoenixExample.ArticlesController do
        use PhoenixExample.Web, :controller

        def index(conn, _params) do
          render conn, model: PhoenixExample.Repo.all(PhoenixExample.Article)
        end

        def show(conn, params) do
          render conn, model: PhoenixExample.Repo.get(PhoenixExample.Article, params[:id])
        end

      end

  """

  @doc false
  defmacro __using__(_) do
    quote do
      use JaSerializer

      def render("index.json", data) do
        JaSerializer.PhoenixView.render(__MODULE__, data)
      end

      def render("index.json-api", data) do
        JaSerializer.PhoenixView.render_and_serialize(__MODULE__, data)
      end

      def render("show.json", data) do
        JaSerializer.PhoenixView.render(__MODULE__, data)
      end

      def render("show.json-api", data) do
        JaSerializer.PhoenixView.render_and_serialize(__MODULE__, data)
      end

      def render("errors.json", data) do
        JaSerializer.PhoenixView.render_errors(data)
      end

      def render("errors.json-api", data) do
        JaSerializer.PhoenixView.render_and_serialize_errors(data)
      end
    end
  end

  @doc """
  Extracts the model and opts from the data passed to render and returns
  result of formatting.
  """
  def render(serializer, data) do
    model = find_model(serializer, data)
    serializer.format(model, data[:conn], data[:opts] || [])
  end

  @doc """
  Calls render/2 then encodes the result with the JSON encoder defined in
  phoenix config.
  """
  def render_and_serialize(serializer, data) do
    render(serializer, data) |> encoder.encode!
  end

  @doc """
  Extracts the errors and opts from the data passed to render and returns
  result of formatting.

  `data` is expected to be either an invalid `Ecto.Changeset` or preformatted
  errors as described in `JaSerializer.ErrorSerializer`.
  """
  def render_errors(data) do
    errors = (data[:model] || data[:data] || data[:errors])
    errors
    |> error_serializer
    |> apply(:format, [errors, data[:conn], data[:opts]])
  end

  defp error_serializer(%Ecto.Changeset{}) do
    JaSerializer.EctoErrorSerializer
  end

  defp error_serializer(_) do
    JaSerializer.ErrorSerializer
  end

  @doc """
  Calls render_errors/1 then encodes the result with the JSON encoder defined
  in phoenix config.
  """
  def render_and_serialize_errors(data) do
    data
    |> render_errors
    |> encoder.encode!
  end

  defp find_model(serializer, data) do
    data[:model]
    || data[:data]
    || data[singular_type(serializer.type)]
    || data[plural_type(serializer.type)]
    || raise "Unable to find model to serialize."
  end

  defp singular_type(type) do
    type
    |> Inflex.singularize
    |> String.to_atom
  end

  defp plural_type(type) do
    type
    |> Inflex.pluralize
    |> String.to_atom
  end

  defp encoder do
    Application.get_env(:phoenix, :format_encoders)
    |> Keyword.get(:json, Poison)
  end
end
