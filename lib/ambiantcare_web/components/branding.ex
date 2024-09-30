defmodule AmbiantcareWeb.Components.Branding do
  use Phoenix.Component

  attr :class, :string, default: ""

  def logo(assigns) do
    ~H"""
    <div class={[
      "justify-center p-4 rounded flex flex-row gap-0.5 font-semibold",
      @class
    ]}>
      <span class="text-blue-600">ambiant</span>
      <span class="bg-blue-600 px-2 rounded text-white flex flex-row items-end">
        <svg width="10" height="10" xmlns="http://www.w3.org/2000/svg" class="mb-0.5">
          <circle cx="3" cy="3" r="3" fill="white" />
        </svg>
        Care
      </span>
    </div>
    """
  end
end
