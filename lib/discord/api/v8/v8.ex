defmodule Discord.Api.V8 do
  @base_url "https://discord.com/api/v8/"
  def base_headers,
    do: [
      {"Authorization", "Bot " <> Application.get_env(:virtualCrypto, :bot_token)},
      {"Content-Type", "application/json"}
    ]

  defp make_params(params) do
    "?" <> (params |> Enum.map(fn {name, value} -> name <> "=" <> value end) |> Enum.join("&"))
  end

  def get(paths, []) do
    HTTPoison.get(@base_url <> Enum.join(paths, "/"), base_headers())
  end

  def get(paths, params) do
    HTTPoison.get(@base_url <> Enum.join(paths, "/") <> make_params(params), base_headers())
  end

  def post(paths, body) do
    HTTPoison.post(@base_url <> Enum.join(paths, "/"), Jason.encode!(body), base_headers())
  end

  def get_guild_members(guild_id, limit \\ 1000) do
    {:ok, response} =
      get(["guilds", to_string(guild_id), "members"], [{"limit", to_string(limit)}])

    Jason.decode!(response.body)
  end

  def get_guild_member_with_status_code(guild_id, user_id) do
    {:ok, response} = get(["guilds", to_string(guild_id), "members", to_string(user_id)], [])
    {response.status_code, Jason.decode!(response.body)}
  end

  def roles(guild_id) do
    {:ok, response} = get(["guilds", to_string(guild_id), "roles"], [])
    Jason.decode!(response.body)
  end

  def get_guild(guild_id, with_counts \\ false) do
    {:ok, response} =
      get(["guilds", to_string(guild_id)], [{"with_counts", to_string(with_counts)}])

    Jason.decode!(response.body)
  end
end
