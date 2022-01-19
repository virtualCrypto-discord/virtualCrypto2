defmodule VirtualCryptoWeb.ConnectApplication do
  use Phoenix.LiveView
  alias VirtualCrypto.Auth

  def render(assigns) do
    VirtualCryptoWeb.LiveView.render("connect.html", assigns)
  end

  def mount(params, session, socket) do
    user = session["user"]

    case UUID.info(params["id"]) do
      {:ok, _} ->
        app = Auth.get_user_application(user.id, params["id"])

        case app do
          nil ->
            {:ok, push_redirect(socket, to: "/applications/" <> params["id"])}

          _ ->
            {application, app_user, _redirect_uris} = app

            {:ok,
             assign(socket,
               app: application,
               message: "",
               uuid: "https://vcrypto.sumidora.com/applications/verification?q=" <> UUID.uuid4(),
               bot_id: "",
               guild_id: "",
               app_user_id: app_user.id,
               now_id: app_user.discord_id,
               edit: false
             )}
        end

      {:error, _} ->
        {:ok, push_redirect(socket, to: "/applications/" <> params["id"])}
    end
  end

  defp failed(socket, msg, edit \\ false) do
    {:noreply, socket |> assign(message: ~s/認証に失敗しました。#{msg}/, edit: edit)}
  end

  def handle_event("verify", _data, socket) do
    assigns = socket.assigns

    with {:fetch_integrations, {200, integrations}} <-
           {:fetch_integrations,
            Discord.Api.Raw.get_guild_integrations_with_status_code(assigns.guild_id)},
         {:find_target_integration, %{} = integration} <-
           {:find_target_integration,
            integrations
            |> Enum.find(fn integration ->
              id = assigns.bot_id

              case integration do
                %{"application" => %{"bot" => %{"id" => ^id}}} -> true
                _ -> false
              end
            end)},
         {:validate_description, true, _} <-
           {:validate_description,
            String.contains?(integration["application"]["description"], assigns.uuid),
            integration},
         {:update_discord_user_id, {:ok, _}} <-
           {:update_discord_user_id,
            VirtualCrypto.ConnectUser.set_discord_user_id(
              assigns.app_user_id,
              String.to_integer(assigns.bot_id)
            )} do
      {:noreply,
       socket
       |> assign(message: "認証成功しました。トークンは削除して差し支えありません。", now_id: assigns.bot_id, edit: false)}
    else
      {:fetch_integrations, {403, _data}} ->
        case Discord.Api.Raw.get_guild_with_status_code(assigns.guild_id) do
          {403, _} ->
            failed(
              socket,
              "Integrationが取得できませんでした。VirtualCryptoがサーバーに導入されていることならびにサーバーIDを確認してください。",
              edit: true
            )

          {200, guild} ->
            failed(
              socket,
              "Integrationが取得できませんでした。VirtualCryptoがサーバー、#{guild["name"]}でサーバーの管理の権限を持っていることを確認してください。",
              edit: true
            )
        end

      {:fetch_integrations, {404, _data}} ->
        failed(socket, "指定されたサーバーIDのサーバーは存在しません。", edit: false)

      {:fetch_integrations, {code, _data}} ->
        failed(socket, ~s/Integrationの取得が#{code}で失敗しました。/, edit: true)

      {:find_target_integration, _} ->
        # must get flesh data
        case Discord.Api.Raw.get_user_with_status(assigns.bot_id) do
          {200, %{"username" => username, "discriminator" => discriminator, "bot" => true}} ->
            case Discord.Api.Raw.get_guild_with_status_code(assigns.guild_id) do
              {200, %{"name" => name}} ->
                failed(
                  socket,
                  "取得したIntegrationに指定のIdのIntegrationが見つかりませんでした。サーバー、#{name}にBot、#{username}##{discriminator}が導入されていることを確認してください。",
                  edit: true
                )
            end

          {200, %{"username" => username, "discriminator" => discriminator}} ->
            failed(
              socket,
              "取得したIntegrationに指定のIdのIntegrationが見つかりませんでした。#{username}##{discriminator}はBotではありません。",
              edit: true
            )

          {404, _} ->
            failed(
              socket,
              "指定されたユーザーIDのユーザーは存在しません。ユーザーIDを確認してください。",
              edit: false
            )
        end

      {:validate_description, _, integration} ->
        case integration do
          %{"application" => %{"bot" => %{"username" => username}}} ->
            failed(
              socket,
              [
                "取得したIntegrationのDescriptionにトークンが含まれていません。",
                "BotのユーザーIDならびにDescription、Discoed Developer Portalにおいて設定が保存されていることを確認してください。",
                "(Botのユーザー名: #{username})"
              ]
              |> Enum.join(""),
              edit: true
            )
        end

      {:update_discord_user_id, {:error, :conflicted_user_id}} ->
        failed(socket, "すでにそのBotは別のApplicationに紐付けられています。")

      {:update_discord_user_id, {:error, _}} ->
        failed(socket, "データベースの更新中にエラーが発生しました。時間を置いてやり直してください。")
    end
  end

  def handle_event("change", data, socket) do
    {:noreply, assign(socket, bot_id: data["bot_id"], guild_id: data["guild_id"], edit: true)}
  end
end
