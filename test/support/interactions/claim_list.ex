defmodule InteractionsControllerTest.Claim.List.Helper do
  defmodule FakeApi do
    def post_webhook_message("1234578901234567", "discord_interaction_token", body) do
      send(self(), {:webhook, body})
      {200, nil}
    end
  end

  def fake_api(%{conn: conn} = ctx) do
    conn = VirtualCryptoWeb.Plug.DiscordApiService.set_service(conn, FakeApi)
    %{ctx | conn: conn}
  end

  def action_data(
        data,
        user
      ) do
    %{
      type: 3,
      data: data |> Map.put(:component_type, 2),
      member: %{
        user: %{
          id: to_string(user)
        },
        permissions: to_string(0xFFFFFFFFFFFFFFFF)
      },
      token: "discord_interaction_token",
      application_id: "1234578901234567",
      guild_id: to_string(494_780_225_280_802_817)
    }
  end

  defmacro __using__(opts) do
    action = Keyword.fetch!(opts, :action)

    quote do
      import InteractionsControllerTest.Claim.List.Helper

      def test_common(conn, claims, user_id) do
        alias VirtualCryptoWeb.Interaction.Claim.List.Options, as: ListOptions
        alias VirtualCryptoWeb.Interaction.Claim.List.Helper
        alias VirtualCryptoWeb.Interaction.CustomId
        alias VirtualCryptoWeb.Interaction.CustomId.UI.Button
        encoded_claims_ids = Helper.encode_claim_ids(claims)

        options = %VirtualCryptoWeb.Interaction.Claim.List.Options{
          approved: false,
          canceled: false,
          denied: false,
          pending: true,
          page: 1,
          position: :all,
          related_user: 0
        }

        custom_id =
          CustomId.encode(
            Button.claim_action(unquote(action)) <>
              ListOptions.encode(options) <> encoded_claims_ids
          )

        conn =
          execute_interaction(
            conn,
            action_data(
              %{
                custom_id: custom_id
              },
              user_id
            )
          )

        assert %{} = json_response(conn, 200)
        assert_received {:webhook, body}
        body
      end

      defp test_invalid_operator(conn, claims, user_id) do
        assert %{
                 content: "エラー: この請求に対してこの操作を行う権限がありません。",
                 flags: 64
               } == test_common(conn, claims, user_id)
      end

      defp test_invalid_status(conn, claims, user_id) do
        assert %{
                 content: "エラー: 処理しようとした請求はすでに処理済みです。",
                 flags: 64
               } == test_common(conn, claims, user_id)
      end
    end
  end
end
