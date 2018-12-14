defmodule JaSerializer.Builder.PaginationLinksTest do
  use ExUnit.Case
  alias JaSerializer.Builder.PaginationLinks

  setup do
    on_exit(fn ->
      Application.delete_env(:ja_serializer, :page_key)
      Application.delete_env(:ja_serializer, :page_base_url)
      Application.delete_env(:ja_serializer, :page_size_key)
      Application.delete_env(:ja_serializer, :page_number_key)
    end)
  end

  test "pagination" do
    data = %{
      number: 10,
      size: 20,
      total: 30
    }

    conn = %Plug.Conn{query_params: %{}}
    links = PaginationLinks.build(data, conn)
    assert URI.decode(links[:first]) == "?page[number]=1&page[size]=20"
    assert URI.decode(links[:prev]) == "?page[number]=9&page[size]=20"
    assert URI.decode(links[:next]) == "?page[number]=11&page[size]=20"
    assert URI.decode(links[:last]) == "?page[number]=30&page[size]=20"
  end

  test "pagination keys are configurable" do
    Application.put_env(:ja_serializer, :page_key, "pages")
    Application.put_env(:ja_serializer, :page_number_key, "offset")
    Application.put_env(:ja_serializer, :page_size_key, "limit")

    data = %{
      number: 10,
      size: 20,
      total: 30
    }

    conn = %Plug.Conn{query_params: %{}}
    links = PaginationLinks.build(data, conn)

    assert URI.decode(links[:first]) == "?pages[limit]=20&pages[offset]=1"
    assert URI.decode(links[:prev]) == "?pages[limit]=20&pages[offset]=9"
    assert URI.decode(links[:next]) == "?pages[limit]=20&pages[offset]=11"
    assert URI.decode(links[:last]) == "?pages[limit]=20&pages[offset]=30"
  end

  test "when current page is first, do not include first, prev links" do
    data = %{
      number: 1,
      size: 20,
      total: 30
    }

    conn = %Plug.Conn{query_params: %{}}

    links =
      data
      |> PaginationLinks.build(conn)
      |> Map.keys()
      |> Enum.sort()

    assert Enum.sort([:self, :last, :next]) == links
  end

  test "when current page is in the middle, includes all links" do
    data = %{
      number: 10,
      size: 20,
      total: 30
    }

    conn = %Plug.Conn{query_params: %{}}

    links =
      data
      |> PaginationLinks.build(conn)
      |> Map.keys()
      |> Enum.sort()

    assert Enum.sort([:self, :first, :prev, :last, :next]) == links
  end

  test "when current page is the last, do not include last, next links" do
    data = %{
      number: 30,
      size: 20,
      total: 30
    }

    conn = %Plug.Conn{query_params: %{}}

    links =
      data
      |> PaginationLinks.build(conn)
      |> Map.keys()
      |> Enum.sort()

    assert Enum.sort([:self, :first, :prev]) == links
  end

  test "when result contains no data, include only self link" do
    data = %{
      number: 1,
      size: 20,
      total: 0
    }

    conn = %Plug.Conn{query_params: %{}}

    links =
      data
      |> PaginationLinks.build(conn)
      |> Map.keys()
      |> Enum.sort()

    assert Enum.sort([:self]) == links
  end

  test "url is taken from current conn url, params forwarded" do
    data = %{
      number: 30,
      size: 20,
      total: 30
    }

    conn = %Plug.Conn{
      query_params: %{"filter" => %{"foo" => "bar"}},
      request_path: "/api/v1/posts/"
    }

    links = PaginationLinks.build(data, conn)

    assert links[:first] ==
             "/api/v1/posts/?filter[foo]=bar&page[number]=1&page[size]=20"
  end

  test "url opts override conn url, old page params ignored" do
    data = %{
      number: 30,
      size: 20,
      total: 30,
      base_url: "/api/v2/posts"
    }

    conn = %Plug.Conn{
      query_params: %{"page" => %{"page" => 1}},
      request_path: "/api/v1/posts/"
    }

    links = PaginationLinks.build(data, conn)

    assert links[:first] == "/api/v2/posts?page[number]=1&page[size]=20"
  end

  test "url opts override conn url, old page params ignored when page_key is nil" do
    Application.put_env(:ja_serializer, :page_key, nil)

    data = %{
      number: 1,
      size: 20,
      total: 30
    }

    conn = %Plug.Conn{
      query_params: %{"number" => 4}
    }

    links = PaginationLinks.build(data, conn)

    assert links[:self] == "?number=1&size=20"
  end

  test "base_url can be configured globally" do
    Application.put_env(
      :ja_serializer,
      :page_base_url,
      "http://api.example.com"
    )

    data = %{
      number: 10,
      size: 20,
      total: 30
    }

    conn = %Plug.Conn{query_params: %{}}
    links = PaginationLinks.build(data, conn)

    assert URI.decode(links[:first]) ==
             "http://api.example.com?page[number]=1&page[size]=20"

    assert URI.decode(links[:prev]) ==
             "http://api.example.com?page[number]=9&page[size]=20"

    assert URI.decode(links[:next]) ==
             "http://api.example.com?page[number]=11&page[size]=20"

    assert URI.decode(links[:last]) ==
             "http://api.example.com?page[number]=30&page[size]=20"
  end

  test "base_url can be overridden locally" do
    Application.put_env(
      :ja_serializer,
      :page_base_url,
      "http://api.example.com"
    )

    data = %{
      number: 10,
      size: 20,
      total: 30,
      base_url: "http://api2.example.com"
    }

    conn = %Plug.Conn{query_params: %{}}
    links = PaginationLinks.build(data, conn)

    assert URI.decode(links[:first]) ==
             "http://api2.example.com?page[number]=1&page[size]=20"

    assert URI.decode(links[:prev]) ==
             "http://api2.example.com?page[number]=9&page[size]=20"

    assert URI.decode(links[:next]) ==
             "http://api2.example.com?page[number]=11&page[size]=20"

    assert URI.decode(links[:last]) ==
             "http://api2.example.com?page[number]=30&page[size]=20"
  end

  test "base_url use current path for producing valid urls" do
    Application.put_env(
      :ja_serializer,
      :page_base_url,
      "http://api.example.com"
    )

    data = %{
      number: 10,
      size: 20,
      total: 30
    }

    conn = %Plug.Conn{query_params: %{}, request_path: "/api/v1/resources"}
    links = PaginationLinks.build(data, conn)

    assert URI.decode(links[:first]) ==
             "http://api.example.com/api/v1/resources?page[number]=1&page[size]=20"

    assert URI.decode(links[:prev]) ==
             "http://api.example.com/api/v1/resources?page[number]=9&page[size]=20"

    assert URI.decode(links[:next]) ==
             "http://api.example.com/api/v1/resources?page[number]=11&page[size]=20"

    assert URI.decode(links[:last]) ==
             "http://api.example.com/api/v1/resources?page[number]=30&page[size]=20"
  end
end
