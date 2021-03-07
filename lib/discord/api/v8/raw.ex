defmodule Discord.Api.V8.Raw do
  alias Discord.Api.Behavior
  @behaviour Behavior
  @base_url "https://discord.com/api/v8/"
  def base_headers,
    do: [
      {"Authorization", "Bot " <> Application.get_env(:virtualCrypto, :bot_token)},
      {"Content-Type", "application/json"}
    ]

  defp make_params(params) do
    "?" <> (params |> Enum.map(fn {name, value} -> name <> "=" <> value end) |> Enum.join("&"))
  end

  defp get(paths, []) do
    HTTPoison.get(@base_url <> Enum.join(paths, "/"), base_headers())
  end

  defp get(paths, params) do
    HTTPoison.get(@base_url <> Enum.join(paths, "/") <> make_params(params), base_headers())
  end

  @impl Behavior
  def get_guild_members(guild_id, limit \\ 1000) do
    {:ok, response} =
      get(["guilds", to_string(guild_id), "members"], [{"limit", to_string(limit)}])

    Jason.decode!(response.body)
  end

  @impl Behavior
  def get_guild_member_with_status_code(guild_id, user_id) do
    {:ok, response} = get(["guilds", to_string(guild_id), "members", to_string(user_id)], [])
    {response.status_code, Jason.decode!(response.body)}
  end

  @impl Behavior
  def get_roles(guild_id) do
    {:ok, response} = get(["guilds", to_string(guild_id), "roles"], [])
    Jason.decode!(response.body)
  end

  @impl Behavior
  def get_guild(guild_id, with_counts \\ false) do
    {200, body} = get_guild_with_status_code(guild_id, with_counts)

    body
  end

  @impl Behavior
  def get_guild_with_status_code(guild_id, with_counts \\ false) do
    {:ok, response} =
      get(["guilds", to_string(guild_id)], [{"with_counts", to_string(with_counts)}])

    {response.status_code, Jason.decode!(response.body)}
  end

  @impl Behavior
  def get_user(user_id) do
    {200, body} = get_user_with_status(user_id)

    body
  end

  @impl Behavior
  def get_user_with_status(user_id) do
    {:ok, response} = get(["users", to_string(user_id)], [])

    {response.status_code, Jason.decode!(response.body)}
  end

  @impl Behavior
  def get_guild_integrations_with_status_code(guild_id) do
    {:ok, response} = get(["guilds", to_string(guild_id), "integrations"], [])
    {response.status_code, Jason.decode!(response.body)}
  end
end
