defmodule VirtualCryptoWeb.ClaimTest.TestDiscordAPI do
  # @behaviour Discord.Api.Behaviour

  def get_user(user_id) do
    %{"id" => to_string(user_id)}
  end

  def get_user_with_status(user_id) do
    {200, %{"id" => to_string(user_id)}}
  end
end
