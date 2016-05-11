defmodule JaSerializer.ContentTypeNegotiation do
  @moduledoc """
  This plug provides content type negotiation by validating the
  `content-type` and `accept` headers.

  The proper jsonapi.org content type is: `application/vnd.api+json`.

  As per [the spec](http://jsonapi.org/format/#content-negotiation-servers)
  this plug does three things.

  1. Returns 415 unless the content-type header is correct.
  2. Returns 406 unless the accept header is correct.
  3. Registers a before send hook to set the content-type if not already set.

  ## Usage

  Just include in your plug stack:

      plug JaSerializer.ContentTypeNegotiation

  """

  use Plug.Builder

  plug :verify_content_type
  plug :verify_accepts
  plug :set_content_type

  @jsonapi "application/vnd.api+json"

  def verify_content_type(%Plug.Conn{method: "HEAD"} = conn, _o), do: conn
  def verify_content_type(%Plug.Conn{method: "GET"} = conn, _o), do: conn
  def verify_content_type(%Plug.Conn{method: "DELETE"} = conn, _o), do: conn
  def verify_content_type(%Plug.Conn{} = conn, _o) do
    if Enum.member?(get_req_header(conn, "content-type"), @jsonapi) do
      conn
    else
      halt send_resp(conn, 415, "")
    end
  end

  def verify_accepts(conn, _opts) do
    accepts = conn
              |> get_req_header("accept")
              |> Enum.flat_map(&(String.split(&1, ",")))
              |> Enum.map(&String.strip/1)

    cond do
      accepts == []                          -> conn
      Enum.member?(accepts, @jsonapi)        -> conn
      Enum.member?(accepts, "application/*") -> conn
      Enum.member?(accepts, "*/*")           -> conn
      true                                   -> halt send_resp(conn, 406, "")
    end
  end

  def set_content_type(conn, _opts) do
    register_before_send conn, fn(later_conn) ->
      update_resp_header(later_conn, "content-type", @jsonapi, &(&1))
    end
  end
end
