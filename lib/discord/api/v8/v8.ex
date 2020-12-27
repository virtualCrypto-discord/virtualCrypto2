defmodule Discord.Api.V8 do
  @base_url "https://discord.com/api/v8/"
  @base_headers [
    {"Authorization", "Bot " <> Application.get_env(:virtualCrypto, :bot_token)},
    {"Content-Type", "application/json"}]

  defp make_params params do
    "?" <> (params |> Enum.map(fn {name, value} -> name <> "=" <> value end) |> Enum.join("&"))
  end

  def get(paths, []) do
    HTTPoison.start
    HTTPoison.get(@base_url <> Enum.join(paths, "/"), @base_headers)
  end

  def get(paths, params) do
    HTTPoison.start
    HTTPoison.get(@base_url <> Enum.join(paths, "/") <> make_params(params), @base_headers)
  end

  def post(paths, body) do
    HTTPoison.start
    HTTPoison.post(@base_url <> Enum.join(paths, "/"), Jason.encode!(body), @base_headers)
  end

  def get_guild_members(guild_id, limit \\ 1000) do
    {:ok, response} = get(["guilds", to_string(guild_id), "members"], [{"limit", to_string(limit)}])
    Jason.decode!(response.body)
  end

  def get_guild(guild_id, with_counts \\ false) do
    {:ok, response} = get(["guilds", to_string(guild_id)], [{"with_counts", to_string(with_counts)}])
    Jason.decode!(response.body)
  end
end
