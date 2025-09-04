defmodule VirtualCryptoWeb.UI.Header do
  use VirtualCryptoWeb, :ui
  alias VirtualCryptoWeb.UI.Sidebar

  embed_templates "header_html/*"

  def header(assigns) do
    ~H"""
    <div class="sticky top-0 z-40 flex h-16 shrink-0 items-center gap-x-4 border-b border-gray-200 bg-white px-4 shadow-xs sm:gap-x-6 sm:px-6 lg:px-8 dark:border-white/10 dark:bg-gray-900">
      <Sidebar.open_sidebar_button />
      <div aria-hidden="true" class="h-6 w-px bg-gray-900/10 lg:hidden dark:bg-white/10"></div>

      <div class="flex flex-1 gap-x-4 self-stretch lg:gap-x-6">
        <.search_bar />
        <div class="flex items-center gap-x-4 lg:gap-x-6">
          <.notification />
          <div
            aria-hidden="true"
            class="hidden lg:block lg:h-6 lg:w-px lg:bg-gray-900/10 dark:lg:bg-gray-100/10"
          >
          </div>
          <.profile />

          <Layouts.theme_toggle />
        </div>
      </div>
    </div>
    """
  end

  def wrapper(assigns) do
    ~H"""
    <div class="lg:pl-72">
      <.header />
      <main class="py-10">
        <div class="px-4 sm:px-6 lg:px-8">
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    """
  end
end
