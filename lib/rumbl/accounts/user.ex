defmodule Rumbl.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    has_many :videos, Rumbl.Videos.Video
    has_many :annotations, Rumbl.Annotation

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :username, :password])
    |> validate_length(:username, min: 1, max: 20)
    |> validate_required([:name, :username, :password])
    |> unique_constraint(:username)
  end

  def registration_changeset(model, attrs) do
    model
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_length(:password, min: 6, max: 100)
    |> put_pass_hash()
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(pass))
      _ ->
        changeset
    end
  end
end
