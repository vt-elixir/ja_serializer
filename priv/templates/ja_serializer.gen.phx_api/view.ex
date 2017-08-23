defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>View do
  use <%= inspect context.web_module %>, :view
  use JaSerializer.PhoenixView
  
  attributes [<%= (schema.types |> Enum.map(fn({k, v}) -> ":#{k}" end)) ++ [":inserted_at", ":updated_at"] |> Enum.join(", ") %>]
  <%= for {ref, key, _, _} <- schema.assocs do %>
  has_one :<%= ref %>,
    field: :<%= key %>,
    type: "<%= ref %>"<% end %>
end
