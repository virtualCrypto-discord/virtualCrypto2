defmodule VirtualCryptoWeb.ConnectApplication do
  use Phoenix.LiveView
  alias VirtualCrypto.Auth

  def render( assigns ) do
    VirtualCryptoWeb.LiveView.render("connect.html", assigns)
  end

  def mount( _params, _session, socket ) do
    user = _session["user"]
    app = Auth.get_user_application(user.id, _params["id"])
    case app do
      nil -> { :ok, push_redirect(socket, to: "/applications/" <> _params["id"]) }
      _ ->
        {application, app_user, redirect_uris} = app
        { :ok, assign( socket,
          app: application,
          message: "",
          uuid: UUID.uuid4(),
          bot_id: "",
          guild_id: "",
          now_id: app_user.discord_id,
          edit: false
        ) }
    end
  rescue
    err ->
      { :ok, push_redirect(socket, to: "/applications/" <> _params["id"]) }
  end

  def handle_event("verify", data, socket) do
    assigns = socket.assigns
    bots = Discord.Api.V8.Raw.get_guild_integrations(assigns.guild_id)
      |> Enum.filter(fn integration ->
          integration["application"]["bot"]["id"] == assigns.bot_id &&
          String.match?(integration["application"]["description"], ~r/#{assigns.uuid}/) end)
      |> Enum.empty?()
    if !bots do
      {1, nil} = VirtualCrypto.User.set_discord_user_id(assigns.app.id, String.to_integer(assigns.bot_id))
      { :noreply, socket |> assign(message: "認証成功しました。", now_id: assigns.bot_id, edit: false) }
    else
      { :noreply, socket |> assign(message: "認証に失敗しました。再度お試しください。", edit: false) }
    end
  rescue
    _ -> { :noreply, socket |> assign(message: "認証に失敗しました。再度お試しください。", edit: false) }
  end

  def handle_event("change", data, socket) do
    { :noreply, assign( socket, bot_id: data["bot_id"], guild_id: data["guild_id"], edit: true) }
  end
end
