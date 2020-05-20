defmodule RumblWeb.VideoChannel do
  import Ecto.Query, warn: false
  use RumblWeb, :channel
  alias Rumbl.Accounts
  alias Rumbl.Videos
  alias RumblWeb.AnnotationView

  def join("videos:" <> video_id, params, socket) do
    last_seen_id = params["last_seen_id"] || 0
    video_id = String.to_integer(video_id)
    video = Videos.get_video!(video_id)

    annotations =
      Rumbl.Repo.all(
        from a in Ecto.assoc(video, :annotations),
          where: a.id > ^last_seen_id,
          order_by: [asc: a.at, asc: a.id],
          limit: 200,
          preload: [:user]
      )

    resp = %{
      annotations: Phoenix.View.render_many(annotations, AnnotationView, "annotation.json")
    }

    {:ok, resp, assign(socket, :video_id, video_id)}
  end

  def handle_in("new_annotation", params, socket) do
    user = Accounts.get_user!(socket.assigns.user_id)

    changeset =
      user
      |> Ecto.build_assoc(:annotations, video_id: socket.assigns.video_id)
      |> Rumbl.Annotation.changeset(params)

    case Rumbl.Repo.insert(changeset) do
      {:ok, annotation} ->
        broadcast!(socket, "new_annotation", %{
          id: annotation.id,
          user: RumblWeb.UserView.render("user.json", %{user: user}),
          body: annotation.body,
          at: annotation.at
        })

        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end
end
