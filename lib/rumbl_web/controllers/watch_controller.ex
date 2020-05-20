defmodule RumblWeb.WatchController do
  use RumblWeb, :controller
  alias Rumbl.Videos

  def show(conn, %{"id" => id}) do
    video = Videos.get_video!(id)
    render(conn, "show.html", video: video)
  end
end
