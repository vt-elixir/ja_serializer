defmodule JaSerializer.Builder.TopLevelTest do
  use ExUnit.Case

  defmodule PersonSerializer do
    use JaSerializer
    attributes [:first_name]
  end

  test "pagination with scrivener" do
    p1 = %TestModel.Person{id: "p1", first_name: "p1"}
    page = %Scrivener.Page{
      entries: [p1],
      page_number: 10,
      page_size: 20,
      total_pages: 30
    }
    context = %{
      model: page,
      conn: %Plug.Conn{query_params: %{}},
      serializer: PersonSerializer,
      opts: []
    }
    results = JaSerializer.Builder.TopLevel.build(context)
    [data] = results.data
    links = Enum.map(results.links, &(&1.type)) |> Enum.sort
    assert data.id == "p1"
    assert :first in links
    assert :prev in links
    assert :self in links
    assert :next in links
    assert :last in links
  end
end
