defmodule VirtualCryptoWeb.AppComponents do
  use VirtualCryptoWeb, :html
  alias Phoenix.LiveView.JS
  import VirtualCryptoWeb.CoreComponents

  embed_templates "app_component_layouts/*"

  attr :href, :any, required: true
  attr :icon, :string, required: true
  attr :name, :string, required: true

  def sidebar_nav(assigns) do
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
