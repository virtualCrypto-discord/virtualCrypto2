defmodule VirtualCryptoWeb.Api.InteractionsView.Claim.Common do
  def render_action_result(:approve, claim) do
    "id: #{claim.id}の請求を承諾し、支払いました。"
  end

  def render_action_result(:deny, claim) do
    "id: #{claim.id}の請求を拒否しました。"
  end

  def render_action_result(:cancel, claim) do
    "id: #{claim.id}の請求をキャンセルしました。"
  end
end
