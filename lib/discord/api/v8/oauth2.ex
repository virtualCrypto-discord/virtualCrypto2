defmodule Discord.Api.V8.Oauth2 do
  use OAuth2.Strategy

  @base_url "https://discord.com/api/v6"
  @client_data [
    strategy: OAuth2.Strategy.AuthCode,
    client_id: Application.get_env(:virtualCrypto, :client_id),
    client_secret: Application.get_env(:virtualCrypto, :client_secret),
    token_url: "https://discord.com/api/oauth2/token",
    authorize_url: "https://discord.com/api/oauth2/authorize",
    redirect_uri: Application.get_env(:virtualCrypto, :redirect_uri)
  ]

  @spec exchange_code(String.t(), String.t()) :: OAuth2.Client | :error
  def exchange_code(code, scope \\ "identify") do
    client = OAuth2.Client.new(@client_data)
    try do
      client
      |> put_header("Accept", "application/json")
      |> OAuth2.Client.get_token!(code: code)
    rescue
      _ -> :error
    end
  end

  def get_user_info(client, token) do
    {:ok, response} = @client_data
                      |> Keyword.merge([token: token])
                      |> OAuth2.Client.new()
                      |> OAuth2.Client.get("https://discord.com/api/users/@me")
    Jason.decode!(response.body)
  end

  @spec refresh_token(String.t()) :: OAuth2.Client | :error
  def refresh_token(refresh_token_) do
    try do
      client = @client_data
               |> Keyword.merge([strategy: OAuth2.Strategy.Refresh])
               |> OAuth2.Client.new()
               |> OAuth2.Client.put_param(:refresh_token, refresh_token_)
               |> OAuth2.Client.get_token!()
      {:ok, client}
    rescue
      err -> {:error, err}
    end
  end
end
