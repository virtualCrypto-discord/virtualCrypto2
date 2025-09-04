defmodule VirtualCryptoWeb.AppLive.Balances do
  use VirtualCryptoWeb, :live_view
  import Phoenix.Sync.LiveView
  alias VirtualCrypto.Exterior.User.VirtualCrypto, as: VCUser

  def render(assigns) do
    ~H"""
    <AppLayouts.app flash={@flash}>
      <h1>Content</h1>
      <tbody id="balances" phx-update="stream">
        <tr
          :for={{id, balance} <- @streams.balances}
          id={id}
        >
          <td>{balance.currency_id}</td>
          <td>{balance.amount}</td>
        </tr>
      </tbody>
    </AppLayouts.app>
    """
  end

  def mount(_params, session, socket) do
    user = VirtualCrypto.User.get_user_by_id(session["user"].id)

    {:ok,
     sync_stream(socket, :balances, VirtualCrypto.Money.Query.Balance.get_balances_query(user))}
  end

  def handle_info({:sync, event}, socket) do
    {:noreply, sync_stream_update(socket, event)}
  end
end
