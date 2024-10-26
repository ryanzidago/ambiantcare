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
    <div class="flex flex-col lg:flex-row min-h-full gap-40">
      <%!-- Sidebar: Fixed width on desktop, full width on mobile --%>
      <div class="order-last lg:order-first w-full lg:w-[350px] lg:flex-shrink-0 bg-white border-r border-gray-200">
        <%= render_slot(@sidebar) %>
      </div>

      <%!-- Main content wrapper: Centers content on wide screens --%>
      <div class="order-first lg:order-last flex-grow flex">
        <%!-- Main content: Constrained width for optimal readability --%>
        <div class="w-full max-w-3xl px-4 sm:px-6 lg:px-8 py-6">
          <%= render_slot(@main) %>
        </div>
      </div>
    </div>
    """
  end
end
