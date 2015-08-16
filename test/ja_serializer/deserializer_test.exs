defmodule JaSerializer.DeserializerTest do
  use ExUnit.Case
  use Plug.Test

  defmodule ExamplePlug do
    use Plug.Builder
    plug Plug.Parsers, parsers: [:json], json_decoder: Poison
    plug JaSerializer.Deserializer
    plug :return

    def return(conn, _opts) do
      send_resp(conn, 200, "success")
    end
  end

  @ct "application/vnd.api+json"

  test "Ignores bodyless requests" do
    conn = Plug.Test.conn("GET", "/")
            |> put_req_header("content-type", @ct)
            |> put_req_header("accept", @ct)
    result = ExamplePlug.call(conn, [])
    assert result.params == %{}
  end

  test "Ignores non-jsonapi.org format params" do
    req_body = Poison.encode!(%{"some-nonsense" => "yup"})
    conn = Plug.Test.conn("POST", "/", req_body)
            |> put_req_header("content-type", @ct)
            |> put_req_header("accept", @ct)
    result = ExamplePlug.call(conn, [])
    assert result.params == %{"some-nonsense" => "yup"}
  end

  test "converts attribute key names" do
    req_body = Poison.encode!(%{
      "data" => %{
        "attributes" => %{
          "some-nonsense" => true,
          "foo-bar" => true,
        }
      }
    })
    conn = Plug.Test.conn("POST", "/", req_body)
            |> put_req_header("content-type", @ct)
            |> put_req_header("accept", @ct)
    result = ExamplePlug.call(conn, [])
    assert result.params["data"]["attributes"]["some_nonsense"]
    assert result.params["data"]["attributes"]["foo_bar"]
  end
end
