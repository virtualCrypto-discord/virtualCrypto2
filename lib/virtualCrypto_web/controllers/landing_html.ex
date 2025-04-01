defmodule VirtualCryptoWeb.LandingHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use VirtualCryptoWeb, :html
  import VirtualCryptoWeb.LandingComponents

  embed_templates "landing_html/*"
end
