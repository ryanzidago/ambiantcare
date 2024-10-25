defmodule AmbiantcareWeb.Components.Shell do
  @moduledoc """
  A component for the application shell layout.
  """
  use Phoenix.Component

  @doc """
  Renders the shell layout with the provided sidebar.
  """
  slot :sidebar, required: true
  slot :main, required: true

  def with_sidebar(assigns) do
    ~H"""
    <div class="grid md:grid-cols-8 lg:grid-cols-10 xl:grid-cols-12 align-center min-h-full gap-10">
      <div class="order-last md:order-first  md:col-span-2 lg:col-span-2 xl:col-span-2 bg-gray-100">
        <%= render_slot(@sidebar) %>
      </div>
      <div class="order-first md:order-last md:col-span-6 lg:col-span-6 xl:col-span-6 p-10">
        <%= render_slot(@main) %>
      </div>
    </div>
    """
  end
end
