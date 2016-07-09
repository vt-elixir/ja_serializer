defmodule <%= module %>Controller do
  use <%= base %>.Web, :controller

  alias <%= module %>
  alias JaSerializer.Params

  plug :scrub_params, "data" when action in [:create, :update]

  def index(conn, _params) do
    <%= plural %> = Repo.all(<%= alias %>)
    render(conn, "index.json-api", data: <%= plural %>)
  end

  def create(conn, %{"data" => data = %{"type" => <%= inspect singular %>, "attributes" => _<%= singular %>_params}}) do
    changeset = <%= alias %>.changeset(%<%= alias %>{}, Params.to_attributes(data))

    case Repo.insert(changeset) do
      {:ok, <%= singular %>} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", <%= singular %>_path(conn, :show, <%= singular %>))
        |> render("show.json-api", data: <%= singular %>)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    <%= singular %> = Repo.get!(<%= alias %>, id)
    render(conn, "show.json-api", data: <%= singular %>)
  end

  def update(conn, %{"id" => id, "data" => data = %{"type" => <%= inspect singular %>, "attributes" => _<%= singular %>_params}}) do
    <%= singular %> = Repo.get!(<%= alias %>, id)
    changeset = <%= alias %>.changeset(<%= singular %>, Params.to_attributes(data))

    case Repo.update(changeset) do
      {:ok, <%= singular %>} ->
        render(conn, "show.json-api", data: <%= singular %>)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:errors, data: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    <%= singular %> = Repo.get!(<%= alias %>, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(<%= singular %>)

    send_resp(conn, :no_content, "")
  end

end
