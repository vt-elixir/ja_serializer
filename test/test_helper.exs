ExUnit.start()


defmodule TestModel.Person do
  defstruct [:id, :first_name, :last_name, :twitter]
end

defmodule TestModel.Article do
  defstruct [:id, :title, :author, :comments, :body, :likes, :excerpt]
end

defmodule TestModel.Comment do
  defstruct [:id, :body, :author]
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
