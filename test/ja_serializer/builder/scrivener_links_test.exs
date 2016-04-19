defmodule JaSerializer.Builder.ScrivenerLinksTest do
  use ExUnit.Case
  alias JaSerializer.Builder.ScrivenerLinks

  test "pagination with scrivener" do
    page = %Scrivener.Page{
      page_number: 10,
      page_size: 20,
      total_pages: 30
    }
    context = %{
      data: page,
      conn: %Plug.Conn{query_params: %{}},
      serializer: PersonSerializer,
      opts: []
    }
    links = ScrivenerLinks.build(context)
    assert URI.decode(links[:first]) == "?page[page]=1&page[page-size]=20"
    assert URI.decode(links[:prev]) == "?page[page]=9&page[page-size]=20"
    assert URI.decode(links[:next]) == "?page[page]=11&page[page-size]=20"
    assert URI.decode(links[:last]) == "?page[page]=30&page[page-size]=20"
  end

  test "when current page is first, do not include first, prev links" do
    page = %Scrivener.Page{
      page_number: 1,
      page_size: 20,
      total_pages: 30
    }
    context = %{
      data: page,
      conn: %Plug.Conn{query_params: %{}},
      serializer: PersonSerializer,
      opts: []
    }
    links = ScrivenerLinks.build(context) |> Dict.keys |> Enum.sort
    assert Enum.sort([:self, :last, :next]) == links
  end

  test "when current page is in the middle, includes all links" do
    page = %Scrivener.Page{
      page_number: 10,
      page_size: 20,
      total_pages: 30
    }
    context = %{
      data: page,
      conn: %Plug.Conn{query_params: %{}},
      serializer: PersonSerializer,
      opts: []
    }
    links = ScrivenerLinks.build(context) |> Dict.keys |> Enum.sort
    assert Enum.sort([:self, :first, :prev, :last, :next]) == links
  end

  test "when current page is the last, do not include last, next links" do
    page = %Scrivener.Page{
      page_number: 30,
      page_size: 20,
      total_pages: 30
    }
    context = %{
      data: page,
      conn: %Plug.Conn{query_params: %{}},
      serializer: PersonSerializer,
      opts: []
    }
    links = ScrivenerLinks.build(context) |> Dict.keys |> Enum.sort
    assert Enum.sort([:self, :first, :prev]) == links
  end

  test "when result contains no data, include only self link" do
    page = %Scrivener.Page{
      page_number: 1,
      page_size: 20,
      total_pages: 0
    }
    context = %{
      data: page,
      conn: %Plug.Conn{query_params: %{}},
      serializer: PersonSerializer,
      opts: []
    }
    links = ScrivenerLinks.build(context) |> Dict.keys |> Enum.sort
    assert Enum.sort([:self]) == links
  end

  test "url is taken from current conn url, params forwarded" do
    page = %Scrivener.Page{
      page_number: 30,
      page_size: 20,
      total_pages: 30
    }
    context = %{
      data: page,
      conn: %Plug.Conn{
        query_params: %{"filter" => %{"foo" => "bar"}},
        request_path: "/api/v1/posts/"
      },
      serializer: PersonSerializer,
      opts: []
    }
    links = ScrivenerLinks.build(context)

    assert links[:first] == "/api/v1/posts/?filter[foo]=bar&page[page]=1&page[page-size]=20"
  end

  test "url opts override conn url, old page params ignored" do
    page = %Scrivener.Page{
      page_number: 30,
      page_size: 20,
      total_pages: 30
    }
    context = %{
      data: page,
      conn: %Plug.Conn{
        query_params: %{"page" => %{"page" => 1}},
        request_path: "/api/v1/posts/"
      },
      serializer: PersonSerializer,
      opts: [page: [base_url: "/api/v2/posts"]]
    }
    links = ScrivenerLinks.build(context)

    assert links[:first] == "/api/v2/posts?page[page]=1&page[page-size]=20"
  end
end
