defmodule JaSerializer.EctoErrorSerializerTest do
  use ExUnit.Case

  alias JaSerializer.EctoErrorSerializer

  test "Will correctly format a changeset with an error" do
    expected = %{
      errors: [
        %{
          source: %{pointer: "/data/attributes/title"},
          title: "is invalid",
          detail: "Title is invalid"
        }
      ]
    }

    assert expected == EctoErrorSerializer.format(
      Ecto.Changeset.add_error(%Ecto.Changeset{}, :title, "is invalid")
    )
  end

  test "Will correctly format a changeset with a count error" do
    expected = %{
      errors: [
        %{
          source: %{pointer: "/data/attributes/monies"},
          title: "must be more then 10",
          detail: "Monies must be more then 10"
        }
      ]
    }

    assert expected == EctoErrorSerializer.format(
      Ecto.Changeset.add_error(
        %Ecto.Changeset{},
        :monies,
        {"must be more then %{count}", [count: 10]}
      )
    )
  end

  test "Will correctly format a changeset with multiple errors on one attribute" do
    expected = %{
      errors: [
        %{
          source: %{pointer: "/data/attributes/title"},
          title: "shouldn't be blank",
          detail: "Title shouldn't be blank"
        },
        %{
          source: %{pointer: "/data/attributes/title"},
          title: "is invalid",
          detail: "Title is invalid"
        }
      ]
    }

    changeset = %Ecto.Changeset{}
    |> Ecto.Changeset.add_error(:title, "is invalid")
    |> Ecto.Changeset.add_error(:title, "shouldn't be blank")

    assert expected == EctoErrorSerializer.format(changeset)
  end

end
