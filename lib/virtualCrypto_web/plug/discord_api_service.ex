defmodule VirtualCryptoWeb.Plug.DiscordApiService do
  def init(options), do: options

  def call(conn, opts) do
    conn
    |> set_service(Keyword.get(opts, :service, Discord.Api.Raw))
  end

  @spec get_service(Plug.Conn.t()) :: Discord.Api.Behavior.service()
  def get_service(%Plug.Conn{private: %{discord_api_service_service: service}}) do
    service
  end

  @spec set_service(Plug.Conn.t(), Discord.Api.Behavior.service()) :: Plug.Conn.t()
  def set_service(conn, service) do
    conn
    |> Plug.Conn.put_private(
      :discord_api_service_service,
      service
    )
  end
end
