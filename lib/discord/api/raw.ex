defmodule Discord.Api.Raw do
  alias Discord.Api.Behaviour
  @behaviour Behaviour
  @base_url "https://discord.com/api/v10/"
  def base_headers,
    do: [
      {"Authorization", "Bot #{Application.get_env(:virtualCrypto, :bot_token)}"},
      {"User-Agent",
       "DiscordBot (#{Application.get_env(:virtualCrypto, :discord_ua_website)}, #{Application.get_env(:virtualCrypto, :discord_ua_version)})"},
      {"Content-Type", "application/json"}
    ]

  defp make_params([]) do
    ""
  end

  defp make_params(params) do
    "?" <> (params |> Enum.map(fn {name, value} -> name <> "=" <> value end) |> Enum.join("&"))
  end

  defp get(paths, params) do
    HTTPoison.get(@base_url <> Enum.join(paths, "/") <> make_params(params), base_headers())
  end

  defp patch(paths, params \\ [], body) do
    HTTPoison.patch(
      @base_url <> Enum.join(paths, "/") <> make_params(params),
      Jason.encode!(body),
      base_headers()
    )
  end

  defp post(paths, params, body) do
    HTTPoison.post(
      @base_url <> Enum.join(paths, "/") <> make_params(params),
      Jason.encode!(body),
      base_headers()
    )
  end

  @impl Behaviour
  def get_guild_member_with_status_code(guild_id, user_id) do
    {:ok, response} = get(["guilds", to_string(guild_id), "members", to_string(user_id)], [])
    {response.status_code, Jason.decode!(response.body)}
  end

  @impl Behaviour
  def get_roles(guild_id) do
    {:ok, response} = get(["guilds", to_string(guild_id), "roles"], [])
    Jason.decode!(response.body)
  end

  @impl Behaviour
  def get_guild(guild_id, with_counts \\ false) do
    # FIXME: First aid
    case get_guild_with_status_code(guild_id, with_counts) do
      {200, body} -> body
      _ -> nil
    end
  end

  @impl Behaviour
  def get_guild_with_status_code(guild_id, with_counts \\ false) do
    {:ok, response} =
      get(["guilds", to_string(guild_id)], [{"with_counts", to_string(with_counts)}])

    {response.status_code, Jason.decode!(response.body)}
  end

  @impl Behaviour
  def get_user(user_id) do
    {200, body} = get_user_with_status(user_id)

    body
  end

  @impl Behaviour
  def get_user_with_status(user_id) do
    {:ok, response} = get(["users", to_string(user_id)], [])

    {response.status_code, Jason.decode!(response.body)}
  end

  @impl Behaviour
  def get_guild_integrations_with_status_code(guild_id) do
    {:ok, response} = get(["guilds", to_string(guild_id), "integrations"], [])
    {response.status_code, Jason.decode!(response.body)}
  end

  @impl Behaviour
  def patch_webhook_message(application_id, interaction_token, webhook_message_id, body) do
    {:ok, response} =
      patch(
        [
          "webhooks",
          to_string(application_id),
          interaction_token,
          "messages",
          case webhook_message_id do
            :original -> "@original"
            id -> to_string(id)
          end
        ],
        body
      )

    {response.status_code, Jason.decode!(response.body)}
  end

  @impl Behaviour
  def post_webhook_message(application_id, interaction_token, body) do
    {:ok, response} =
      post(
        [
          "webhooks",
          to_string(application_id),
          interaction_token
        ],
        %{"wait" => "true"},
        body
      )

    {response.status_code, Jason.decode!(response.body)}
  end
end
