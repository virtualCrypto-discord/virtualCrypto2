defmodule VirtualCryptoWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use VirtualCryptoWeb, :controller
      use VirtualCryptoWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      # TODO: Helpers is deprecated, so we should use ~p in tests.
      # https://hexdocs.pm/phoenix/Phoenix.Router.html#module-generating-routes
      use Phoenix.Router, helpers: true

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import VirtualCryptoWeb.Gettext
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: VirtualCryptoWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def app_live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: VirtualCryptoWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import VirtualCryptoWeb.CoreComponents

      # Common modules used in templates
      alias Phoenix.LiveView.JS
      alias VirtualCryptoWeb.Layouts
      alias VirtualCryptoWeb.AppLayouts

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: VirtualCryptoWeb.Endpoint,
        router: VirtualCryptoWeb.Router,
        statics: VirtualCryptoWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
