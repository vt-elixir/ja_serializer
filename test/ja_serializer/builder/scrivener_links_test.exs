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
    assert URI.decode(links[:first]) == "?page[number]=1&page[size]=20"
    assert URI.decode(links[:prev]) == "?page[number]=9&page[size]=20"
    assert URI.decode(links[:next]) == "?page[number]=11&page[size]=20"
    assert URI.decode(links[:last]) == "?page[number]=30&page[size]=20"
  end
end
