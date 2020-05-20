defmodule RumblWeb.Plugs.Auth do
  import Plug.Conn

  import Phoenix.Controller
  import Bcrypt, only: [check_pass: 2, no_user_verify: 0]

  alias Rumbl.Accounts
  alias RumblWeb.Router.Helpers, as: Routes

  def init(_opts) do
  end

  def call(conn, _params) do
    user_id = get_session(conn, :user_id)

    cond do
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)

      user = user_id && Accounts.get_user(user_id) ->
        put_current_user(conn, user)

      true ->
        assign(conn, :current_user, nil)
    end
  end

  def login_by_username_and_pass(conn, username, given_pass) do
    user = Accounts.get_user_by_username(username)

    cond do
      user && check_pass(given_pass, user.password_hash) ->
        {:ok, login(conn, user)}

      user ->
        {:error, :unauthorized, conn}

      true ->
        no_user_verify()
        {:error, :not_found, conn}
    end
  end

  def login(conn, user) do
    conn
    |> put_current_user(user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  defp put_current_user(conn, user) do
    token = Phoenix.Token.sign(conn, "user socket", user.id)

    conn
    |> assign(:current_user, user)
    |> assign(:user_token, token)
  end
end
