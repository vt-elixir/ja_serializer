ExUnit.start()


defmodule TestModel.Person do
  defstruct [:id, :first_name, :last_name, :twitter]
end

defmodule TestModel.Article do
  defstruct [:id, :title, :author, :comments, :body, :tags]
end

defmodule TestModel.Comment do
  defstruct [:id, :body, :author]
end

defmodule TestModel.Tag do
  defstruct [:id, :tag]
end
