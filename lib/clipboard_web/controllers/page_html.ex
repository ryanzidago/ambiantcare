defmodule ClipboardWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use ClipboardWeb, :html

  embed_templates "page_html/*"
end
