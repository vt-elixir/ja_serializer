defmodule JaSerializer.ContentTypeNegotiationTest do
  use ExUnit.Case
  use Plug.Test

  defmodule ExamplePlug do
    use Plug.Builder
    plug(JaSerializer.ContentTypeNegotiation)
    plug(:return)

    def return(conn, _opts) do
      send_resp(conn, 200, "success")
    end
  end

  @valid "application/vnd.api+json"
  @invalid "application/vnd.api+json; charset=utf-8"

  test "Passes proper content-type and accept headers through" do
    conn =
      Plug.Test.conn("POST", "/", %{})
      |> put_req_header("content-type", @valid)
      |> put_req_header("accept", @valid)

    result = ExamplePlug.call(conn, [])
    assert result.status == 200
    assert result.resp_body == "success"
  end

  test "Passes proper content-type and missing accept headers through" do
    conn =
      Plug.Test.conn("POST", "/", %{})
      |> put_req_header("content-type", @valid)

    result = ExamplePlug.call(conn, [])
    assert result.status == 200
    assert result.resp_body == "success"
  end

  test "Passes proper content-type and */* accept headers through" do
    conn =
      Plug.Test.conn("POST", "/", %{})
      |> put_req_header("content-type", @valid)
      |> put_req_header("accept", "*/*")

    result = ExamplePlug.call(conn, [])
    assert result.status == 200
    assert result.resp_body == "success"
  end

  test "Passes proper content-type and application/* accept headers through" do
    conn =
      Plug.Test.conn("POST", "/", %{})
      |> put_req_header("content-type", @valid)
      |> put_req_header("accept", "application/*")

    result = ExamplePlug.call(conn, [])
    assert result.status == 200
    assert result.resp_body == "success"
  end

  test "Passes no content-type and valid accept header through on DELETE" do
    conn =
      Plug.Test.conn("DELETE", "/", %{})
      |> put_req_header("accept", @valid)

    result = ExamplePlug.call(conn, [])
    assert result.status == 200
    assert result.resp_body == "success"
  end

  test "Returns 415 Unsupported Media Type if any media type params" do
    conn =
      Plug.Test.conn("POST", "/", %{})
      |> put_req_header("content-type", @invalid)
      |> put_req_header("accept", @valid)

    result = ExamplePlug.call(conn, [])
    assert result.status == 415
  end

  test "Returns 406 Not Acceptable if all media type params" do
    conn =
      Plug.Test.conn("GET", "/", %{})
      |> put_req_header("accept", @invalid)

    result = ExamplePlug.call(conn, [])
    assert result.status == 406
  end

  test "Sets content type when returning" do
    conn =
      Plug.Test.conn("GET", "/", %{})
      |> put_req_header("accept", @valid)

    result = ExamplePlug.call(conn, [])
    assert [@valid] = get_resp_header(result, "content-type")
  end
end
