defmodule <%= module %>ControllerTest do
  use <%= base %>.ConnCase

  alias <%= module %>
  alias <%= base %>.Repo

  @valid_attrs <%= inspect params %>
  @invalid_attrs %{}

  setup do
    conn = build_conn()
      |> put_req_header("accept", "application/vnd.api+json")
      |> put_req_header("content-type", "application/vnd.api+json")

    {:ok, conn: conn}
  end
  <%= if Enum.count(refs) != 0 do %>
  defp relationships do <%= for ref <- refs do %>
    <%= ref %> = Repo.insert!(%<%= base %>.<%= Phoenix.Naming.camelize(ref) %>{})<% end %>

    %{<%= for ref <- refs do %>
      "<%= ref %>" => %{
        "data" => %{
          "type" => "<%= ref %>",
          "id" => <%= ref %>.id
        }
      },<% end %>
    }
  end<% end %><%= if Enum.count(refs) == 0 do %>
  defp relationships do
    %{}
  end<% end %>

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, <%= singular %>_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    <%= singular %> = Repo.insert! %<%= alias %>{}
    conn = get conn, <%= singular %>_path(conn, :show, <%= singular %>)
    data = json_response(conn, 200)["data"]
    assert data["id"] == "#{<%= singular %>.id}"
    assert data["type"] == "<%= singular %>"<%= for {k, _} <- attrs do %>
    assert data["attributes"]["<%= k %>"] == <%= singular %>.<%= k %><% end %>
  end

  test "does not show resource and instead throw error when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, <%= singular %>_path(conn, :show, <%= if binary_id do %>"11111111-1111-1111-1111-111111111111"<% else %>-1<% end %>)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, <%= singular %>_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "<%= singular %>",
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(<%= alias %>, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, <%= singular %>_path(conn, :create), %{
      "meta" => %{},
      "data" => %{
        "type" => "<%= singular %>",
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    <%= singular %> = Repo.insert! %<%= alias %>{}
    conn = put conn, <%= singular %>_path(conn, :update, <%= singular %>), %{
      "meta" => %{},
      "data" => %{
        "type" => "<%= singular %>",
        "id" => <%= singular %>.id,
        "attributes" => @valid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(<%= alias %>, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    <%= singular %> = Repo.insert! %<%= alias %>{}
    conn = put conn, <%= singular %>_path(conn, :update, <%= singular %>), %{
      "meta" => %{},
      "data" => %{
        "type" => "<%= singular %>",
        "id" => <%= singular %>.id,
        "attributes" => @invalid_attrs,
        "relationships" => relationships
      }
    }

    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    <%= singular %> = Repo.insert! %<%= alias %>{}
    conn = delete conn, <%= singular %>_path(conn, :delete, <%= singular %>)
    assert response(conn, 204)
    refute Repo.get(<%= alias %>, <%= singular %>.id)
  end

end
