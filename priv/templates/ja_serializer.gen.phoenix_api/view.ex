defmodule <%= module %>View do
  use <%= base %>.Web, :view
  use JaSerializer.PhoenixView

  attributes [<%= non_refs |> Enum.map(&(":" <> &1)) |> Enum.join(", ") %>]
  <%= for ref <- refs do %>
  has_one :<%= ref %>,
    field: :<%= ref %>_id,
    type: "<%= ref %>"<% end %>

end
