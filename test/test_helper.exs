ExUnit.start()

defmodule TestModel.Person do
  defstruct [:id, :first_name, :last_name, :twitter, :publishing_agent]
end

defmodule TestModel.Article do
  defstruct [:id, :title, :author, :comments, :body, :likes, :excerpt, :tags]
end

defmodule TestModel.Comment do
  defstruct [:id, :body, :author, :tags]
end

defmodule TestModel.CustomIdComment do
  defstruct [:comment_id, :body, :author]
end

defmodule TestModel.Like do
  defstruct [:id]
end

defmodule TestModel.Excerpt do
  defstruct [:id, :body]
end

defmodule TestModel.Tag do
  defstruct [:id, :tag]
end
