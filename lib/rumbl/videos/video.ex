defmodule Rumbl.Videos.Video do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Rumbl.Permalink, autogenerate: true}
  schema "videos" do
    field :description, :string
    field :title, :string
    field :url, :string
    field :slug, :string

    belongs_to :user, Rumbl.Accounts.User
    belongs_to :category, Rumbl.Category
    has_many :annotations, Rumbl.Annotation

    timestamps()
  end

  @required_fields [:url, :title, :description]
  @optional_fields [:category_id]

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> slugify_title()
    |> assoc_constraint(:category)
    |> validate_required([:url, :title, :description])
  end

  defp slugify_title(changeset) do
    if title = get_change(changeset, :title) do
      put_change(changeset, :slug, slugify(title))
    else
      changeset
    end
  end

  defp slugify(str) do
    str
    |> String.downcase()
    |> String.replace(~r/[^\w-]+/u, "-")
  end

  defimpl Phoenix.Param, for: Rumbl.Videos.Video do
    def to_param(%{slug: slug, id: id}) do
      "#{id}-#{slug}"
    end
  end
end
