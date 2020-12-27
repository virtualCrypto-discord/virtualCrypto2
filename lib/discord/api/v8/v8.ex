defmodule Discord.Api.V8 do
  @base_url "https://discord.com/api/v8/"

  def get(paths, params) do
    HTTPoison.start
    headers = [
      {"Authorization", "Bot " <> Application.get_env(:virtualCrypto, :bot_token)},
      {"Content-Type", "application/json"}]
    HTTPoison.get(@base_url <> Enum.join(paths, "/"), Jason.encode!(params), headers)
  end

  def post(paths, params) do
    HTTPoison.start
    headers = [
      {"Authorization", "Bot " <> Application.get_env(:virtualCrypto, :bot_token)},
      {"Content-Type", "application/json"}]
    HTTPoison.post(@base_url <> Enum.join(paths, "/"), Jason.encode!(params), headers)
  end
end