defmodule VirtualCryptoWeb.LandingComponents do
  use Phoenix.Component
  use Gettext, backend: VirtualCryptoWeb.Gettext
  import VirtualCryptoWeb.CoreComponents

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :title, :string, required: true
  slot :content, required: true

  def faq(assigns) do
    ~H"""
    <div class="group py-6 first:pt-0 last:pb-0" id={"faq-" <> @id}>
      <dt>
        <button
          type="button"
          phx-click={JS.toggle_class("is-open", to: "#faq-" <> @id)}
          class="flex w-full items-start justify-between text-left text-gray-900"
          aria-controls="faq-0"
          aria-expanded="false"
        >
          <span class="text-base/7 font-semibold">{@title}</span>
          <span class="ml-6 flex h-7 items-center">
            <.icon name="hero-plus" class="group-[.is-open]:hidden size-6" />
            <.icon name="hero-minus" class="hidden group-[.is-open]:block size-6" />
          </span>
        </button>
      </dt>
      <dd class="mt-2 pr-12 hidden group-[.is-open]:block">
        <p class="text-base/7 text-gray-600">
          {render_slot(@content)}
        </p>
      </dd>
    </div>
    """
  end
end
