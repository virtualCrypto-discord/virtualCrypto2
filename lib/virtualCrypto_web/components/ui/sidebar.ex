defmodule VirtualCryptoWeb.UI.Sidebar do
  use VirtualCryptoWeb, :ui

  embed_templates "sidebar_html/*"

  attr :href, :any, required: true
  attr :icon, :string, required: true
  attr :name, :string, required: true

  def nav_link(assigns) do
    ~H"""
    <li>
      <a
        href={@href}
        class="group flex gap-x-3 rounded-md p-2 text-base font-semibold hover:bg-gray-100 hover:text-brand transition"
      >
        <.icon name={@icon} class="size-7 shrink-0" /> <span class="my-auto">{@name}</span>
      </a>
    </li>
    """
  end
end
