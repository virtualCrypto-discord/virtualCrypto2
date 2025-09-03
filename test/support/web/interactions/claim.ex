defmodule InteractionsControllerTest.Claim.Helper do
  import InteractionsControllerTest.Helper.Common

  defmacro __using__(_opts) do
    quote do
      import InteractionsControllerTest.Claim.Helper

      def assert_discord_message(conn, message) do
        color_error = VirtualCryptoWeb.Api.Interactions.Util.color_error()

        assert %{
                 "data" => %{
                   "embeds" => [
                     %{
                       "title" => "エラー",
                       "color" => ^color_error,
                       "description" => ^message
                     }
                   ],
                   "flags" => 64
                 },
                 "type" => 4
               } = json_response(conn, 200)
      end

      def test_invalid_operator(conn, action, claim, user) do
        conn =
          execute_interaction(
            conn,
            InteractionsControllerTest.Claim.Helper.patch_from_guild(action, claim.id, user)
          )

        assert_discord_message(conn, "この請求に対してこの操作を行う権限がありません。")
      end

      def test_invalid_status(conn, action, claim, user) do
        conn =
          execute_interaction(
            conn,
            InteractionsControllerTest.Claim.Helper.patch_from_guild(action, claim.id, user)
          )

        assert_discord_message(conn, "この請求に対してこの操作を行うことは出来ません。")
      end
    end
  end

  defp claim_data(action, id) do
    %{
      name: "claim",
      options: [
        %{
          name: action,
          options: [
            %{
              name: "id",
              value: id
            }
          ]
        }
      ]
    }
  end

  def patch_from_guild(action, id, user) do
    execute_from_guild(claim_data(action, id), user)
  end

  def list_from_guild(user) do
    execute_from_guild(
      %{
        name: "claim",
        options: [
          %{
            name: "list",
            options: []
          }
        ]
      },
      user
    )
  end

  def render_claim_name(me, claimant_discord_id, payer_discord_id)
      when me == claimant_discord_id and me == payer_discord_id do
    "📤📥"
  end

  def render_claim_name(me, claimant_discord_id, _payer_discord_id)
      when me == claimant_discord_id do
    "📤"
  end

  def render_claim_name(me, _claimant_discord_id, payer_discord_id)
      when me == payer_discord_id do
    "📥"
  end
end
