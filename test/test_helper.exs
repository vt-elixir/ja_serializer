ExUnit.start()


defmodule TestModel.Person do
  defstruct [:id, :first_name, :last_name, :twitter]
end

defmodule TestModel.Article do
  defstruct [:id, :title, :author, :comments]
end

defmodule TestModel.Comment do
  defstruct [:id, :body, :author]
end
