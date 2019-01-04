defmodule JaSerializer.EctoErrorSerializerTest do
  use ExUnit.Case

  alias JaSerializer.EctoErrorSerializer

  test "Will correctly format a changeset with an error" do
    expected = %{
      "errors" => [
        %{
          source: %{pointer: "/data/attributes/title"},
          title: "is invalid",
          detail: "Title is invalid"
        }
      ],
      "jsonapi" => %{"version" => "1.0"}
    }

    assert expected ==
             EctoErrorSerializer.format(
               Ecto.Changeset.add_error(%Ecto.Changeset{}, :title, "is invalid")
             )
  end

  test "Will correctly format a changeset with a count error" do
    expected = %{
      "errors" => [
        %{
          source: %{pointer: "/data/attributes/monies"},
          title: "must be more than 10",
          detail: "Monies must be more than 10"
        }
      ],
      "jsonapi" => %{"version" => "1.0"}
    }

    assert expected ==
             EctoErrorSerializer.format(
               Ecto.Changeset.add_error(
                 %Ecto.Changeset{},
                 :monies,
                 "must be more than %{count}",
                 count: 10
               )
             )
  end

  test "Will correctly format a changeset with multiple errors on one attribute" do
    expected = %{
      "errors" => [
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
      ],
      "jsonapi" => %{"version" => "1.0"}
    }

    changeset =
      %Ecto.Changeset{}
      |> Ecto.Changeset.add_error(:title, "is invalid")
      |> Ecto.Changeset.add_error(:title, "shouldn't be blank")

    assert expected == EctoErrorSerializer.format(changeset)
  end

  test "Support additional fields per the JSONAPI standard" do
    expected = %{
      "errors" => [
        %{
          id: "1",
          status: "422",
          code: "1000",
          title: "is invalid",
          detail: "Title is invalid",
          source: %{pointer: "/data/attributes/title"},
          links: %{self: "http://localhost"},
          meta: %{author: "Johnny"}
        }
      ],
      "jsonapi" => %{"version" => "1.0"}
    }

    assert expected ==
             EctoErrorSerializer.format(
               Ecto.Changeset.add_error(
                 %Ecto.Changeset{},
                 :title,
                 "is invalid"
               ),
               %{},
               opts: [
                 id: "1",
                 status: "422",
                 code: "1000",
                 links: %{self: "http://localhost"},
                 meta: %{author: "Johnny"}
               ]
             )
  end

  test "Will not consider type hash when formatting a changeset" do
    expected = %{
      "errors" => [
        %{
          source: %{pointer: "/data/attributes/title"},
          title: "is invalid",
          detail: "Title is invalid"
        }
      ],
      "jsonapi" => %{"version" => "1.0"}
    }

    assert expected ==
             EctoErrorSerializer.format(
               Ecto.Changeset.add_error(
                 %Ecto.Changeset{},
                 :title,
                 "is invalid",
                 type: {:array, :integer}
               )
             )
  end

  test "Will correctly format a changeset with a unique error" do
    expected = %{
      "errors" => [
        %{
          source: %{pointer: "/data/attributes/email"},
          title: "has already been taken",
          detail: "Email has already been taken"
        }
      ],
      "jsonapi" => %{"version" => "1.0"}
    }

    assert expected ==
             EctoErrorSerializer.format(
               Ecto.Changeset.add_error(
                 %Ecto.Changeset{},
                 :email,
                 "has already been taken",
                 validation: :unsafe_unique,
                 fields: [:email]
               )
             )
  end
end
