defmodule InteractionsControllerTest.Claim.Helper do
  import InteractionsControllerTest.Helper.Common

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
