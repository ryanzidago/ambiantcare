defmodule AmbiantcareWeb.LandingPageLive do
  use AmbiantcareWeb, :live_view
  use Gettext, backend: AmbiantcareWeb.Gettext

  alias Ambiantcare.Waitlists
  alias Ambiantcare.Waitlists.UserEntry

  alias AmbiantcareWeb.Components.Branding

  alias Ecto.Changeset

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {AmbiantcareWeb.Layouts, :landing_page}}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-20 h-screen overflow-y-scroll">
      <.header_section />
      <.hero_section />
      <.cta_section />
      <.waitlist_form />
      <.how_it_works_section />
      <.team_section />
      <.footer_section />
    </div>
    """
  end

  defp header_section(assigns) do
    links = [
      %{label: gettext("About"), href: "#hero"},
      %{label: gettext("How it works"), href: "#how-it-works"},
      %{label: gettext("Team"), href: "#team"}
    ]

    assigns = assign(assigns, links: links)

    ~H"""
    <header class="sticky top-0 z-10">
      <nav class="bg-white border-gray-200 px-4 lg:px-6 py-2.5 dark:bg-gray-800">
        <div class="flex flex-wrap justify-between items-center mx-auto max-w-screen-xl">
          <Branding.logo />
          <div class="flex items-center lg:order-2">
            <.waitlist_signup_cta />
            <.guided_demo_cta />
            <button
              data-collapse-toggle="mobile-menu-2"
              type="button"
              class="inline-flex items-center p-2 ml-1 text-sm text-gray-500 rounded-lg lg:hidden hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600"
              aria-controls="mobile-menu-2"
              aria-expanded="false"
            >
              <span class="sr-only"><%= gettext("Open main menu") %></span>
              <svg
                class="w-6 h-6"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  fill-rule="evenodd"
                  d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z"
                  clip-rule="evenodd"
                >
                </path>
              </svg>
              <svg
                class="hidden w-6 h-6"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  fill-rule="evenodd"
                  d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                  clip-rule="evenodd"
                >
                </path>
              </svg>
            </button>
          </div>
          <div
            class="hidden justify-between items-center w-full lg:flex lg:w-auto lg:order-1"
            id="mobile-menu-2"
          >
            <ul class="flex flex-col mt-4 font-medium lg:flex-row lg:space-x-8 lg:mt-0">
              <li :for={link <- @links}>
                <a
                  href={link.href}
                  class="block py-2 pr-4 pl-3 text-gray-700 border-b border-gray-100 hover:bg-gray-50 lg:hover:bg-transparent lg:border-0 lg:hover:text-blue-700 lg:p-0 dark:text-gray-400 lg:dark:hover:text-white dark:hover:bg-gray-700 dark:hover:text-white lg:dark:hover:bg-transparent dark:border-gray-700"
                >
                  <%= link.label %>
                </a>
              </li>
            </ul>
          </div>
        </div>
      </nav>
    </header>
    """
  end

  defp hero_section(assigns) do
    ~H"""
    <section class="bg-white dark:bg-gray-900" id="hero">
      <div class="grid max-w-screen-xl px-4 py-8 mx-auto lg:gap-8 xl:gap-0 lg:py-16 lg:grid-cols-12">
        <div class="mr-auto place-self-center lg:col-span-7">
          <h1 class="max-w-2xl mb-4 text-4xl font-extrabold tracking-tight leading-none md:text-5xl xl:text-6xl dark:text-white">
            <%= gettext("Automated medical notes for clinicians") %>
          </h1>
          <p class="max-w-2xl mb-6 font-light text-gray-500 lg:mb-8 md:text-lg lg:text-xl dark:text-gray-400">
            <%= gettext("Press a button and generate medical notes in minutes instead of hours.") %>
          </p>
          <.waitlist_signup_cta />
          <.guided_demo_cta />
        </div>
      </div>
    </section>
    """
  end

  defp cta_section(assigns) do
    ~H"""
    <section class="bg-white dark:bg-gray-900">
      <div class="gap-8 items-center py-8 px-4 mx-auto max-w-screen-xl xl:gap-16 md:grid md:grid-cols-2 sm:py-16 lg:px-6">
        <div style="position: relative; padding-bottom: 56.25%; height: 0;">
          <iframe
            src="https://www.loom.com/embed/bb421e18690d419593e19f01cd974976?sid=4b6006e5-0668-4c16-9551-a033e9b2811f"
            frameborder="0"
            webkitallowfullscreen
            mozallowfullscreen
            allowfullscreen
            style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"
          >
          </iframe>
        </div>
        <div class="mt-4 md:mt-0">
          <h2 class="mb-4 text-4xl tracking-tight font-extrabold text-gray-900 dark:text-white">
            <%= gettext("Focus on what matters: patient care. We'll handle the rest.") %>
          </h2>
          <ul class="font-light text-gray-500 md:text-lg dark:text-gray-400 list-disc list-inside mb-6">
            <li>
              <%= gettext("Save up to 10 hours per week on documentation") %>
            </li>
            <li>
              <%= gettext(
                "Reduce the risk of burnout: more time for you, better patient service, and less bureaucracy"
              ) %>
            </li>
          </ul>
          <.waitlist_signup_cta />
        </div>
      </div>
    </section>
    """
  end

  defp waitlist_form(assigns) do
    ~H"""
    <section class="flex flex-col gap-8 items-center bg-white dark:bg-gray-900" id="waitlist">
      <div>
        <h2 class="mb-4 text-4xl tracking-tight font-extrabold text-gray-900 dark:text-white">
          <%= gettext("Sign up for the waitlist now") %>
        </h2>
        <p class="font-light text-gray-500">
          <%= gettext("The first 100 physicians have free access until February 2025") %>
        </p>
      </div>
      <.form
        for={%{}}
        phx-submit="submit_waitlist_user_entry"
        class="flex flex-col items-center justify-center align-center bg-blue-600 w-full p-8"
      >
        <div class="flex flex-col gap-2">
          <div class="flex flex-row gap-4">
            <.input
              type="email"
              name="email"
              value=""
              label={gettext("Email")}
              label_class="text-zinc-50"
              required
            />
            <.input
              type="tel"
              name="phone_number"
              value=""
              label={gettext("Phone Number")}
              label_class="text-zinc-50"
            />
          </div>
          <div class="flex flex-row gap-4">
            <.input
              type="text"
              name="first_name"
              value=""
              label={gettext("First Name")}
              label_class="text-zinc-50"
              required
            />
            <.input
              type="text"
              name="last_name"
              value=""
              label={gettext("Last Name")}
              label_class="text-zinc-50"
              required
            />
          </div>
          <div class="">
            <.input
              type="text"
              name="specialty"
              value=""
              label={gettext("Specialty")}
              label_class="text-zinc-50"
            />
          </div>
        </div>

        <.button type="submit" class="bg-white hover:bg-white text-zinc-900 mt-8">
          <%= gettext("Join the waitlist") %>
        </.button>
      </.form>
    </section>
    """
  end

  defp how_it_works_section(assigns) do
    ~H"""
    <section class="bg-white dark:bg-gray-900" id="how-it-works">
      <div class="py-8 px-4 mx-auto max-w-screen-xl text-center sm:py-16 lg:px-6">
        <h2 class="mb-4 text-4xl tracking-tight font-extrabold text-gray-900 dark:text-white">
          <%= gettext("How it works") %>
        </h2>
        <div class="mt-8 lg:mt-12 space-y-8 grid grid-cols-1 md:grid-cols-3 lg:grid-cols-3 md:gap-12 md:space-y-0">
          <div>
            <.microphone_icon />
            <h3 class="mb-2 text-xl font-bold dark:text-white "><%= gettext("1. Record") %></h3>
            <p class="mb-4 text-gray-500 dark:text-gray-400">
              <%= gettext("Get your patient's consent and record the consultation.") %>
            </p>
          </div>
          <div>
            <.ambiantcare_icon />
            <h3 class="mb-2 text-xl font-bold dark:text-white"><%= gettext("2. Consult") %></h3>
            <p class="mb-4 text-gray-500 dark:text-gray-400">
              <%= gettext(
                "While the recording is happeninig, proceed as usual and let us handle the rest."
              ) %>
            </p>
          </div>
          <div>
            <.approval_check_icon />
            <h3 class="mb-2 text-xl font-bold dark:text-white"><%= gettext("3. Generate") %></h3>
            <p class="mb-4 text-gray-500 dark:text-gray-400">
              <%= gettext(
                "Our copilot will generate a medical notes in minutes. You can edit and download them."
              ) %>
            </p>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp team_section(assigns) do
    cards = [
      %{
        id: :luigi,
        full_name: "Luigi Espasiano",
        role: gettext("Co-Founder & CEO"),
        avatar_url:
          "https://flowbite.s3.amazonaws.com/blocks/marketing-ui/avatars/bonnie-green.png",
        avatar_alt: "Luigi Espasiano avatar",
        description: gettext(""),
        socials: [
          %{icon_name: "fa-linkedin", url: "https://www.linkedin.com/in/luigiespasiano"},
          %{icon_name: "hero-envelope", url: "mailto:luigi.espasiano@gmail.com"}
        ]
      },
      %{
        id: :ryan,
        full_name: "Ryan Zidago",
        role: gettext("Co-Founder & CTO"),
        avatar_url: "https://flowbite.s3.amazonaws.com/blocks/marketing-ui/avatars/jese-leos.png",
        avatar_alt: "Ryan Zidago avatar",
        description: gettext(""),
        socials: [
          %{icon_name: "fa-linkedin", url: "https://www.linkedin.com/in/ryan-zidago/"},
          %{icon_name: "hero-envelope", url: "mailto:ryan.zidago@protonmail.com"}
        ]
      }
    ]

    assigns = assign(assigns, cards: cards)

    ~H"""
    <section class="dark:bg-gray-900" id="team">
      <div class="py-8 px-4 mx-auto max-w-screen-xl lg:py-16 lg:px-6 ">
        <div class="mx-auto max-w-screen-sm text-center mb-8 lg:mb-16">
          <h2 class="mb-4 text-4xl tracking-tight font-extrabold text-gray-900 dark:text-white">
            <%= gettext("Our Team") %>
          </h2>
          <p class="font-light text-gray-500 lg:mb-16 sm:text-xl dark:text-gray-400"></p>
        </div>
        <div class="grid gap-8 mb-6 lg:mb-16 md:grid-cols-2">
          <div
            :for={card <- @cards}
            class="items-center bg-gray-50 rounded-lg shadow sm:flex dark:bg-gray-800 dark:border-gray-700"
          >
            <%!-- <a href="#">
              <img
                class="w-full rounded-lg sm:rounded-none sm:rounded-l-lg"
                src={card.avatar_url}
                alt={card.avatar_alt}
              />
            </a> --%>
            <div class="p-5">
              <h3 class="text-xl font-bold tracking-tight text-gray-900 dark:text-white">
                <a href="#"><%= card.full_name %></a>
              </h3>
              <span class="text-gray-500 dark:text-gray-400"><%= card.role %></span>
              <p class="mt-3 mb-4 font-light text-gray-500 dark:text-gray-400">
                <%= card.description %>
              </p>
              <div>
                <ul class="flex items-center space-x-4 sm:mt-0">
                  <li :for={social <- card.socials}>
                    <.link
                      href={social.url}
                      class="text-gray-500 hover:text-gray-900 dark:hover:text-white"
                    >
                      <.icon name={social.icon_name} class="text-blue-600" />
                    </.link>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp footer_section(assigns) do
    ~H"""
    <footer class="p-4 bg-white md:p-8 lg:p-10 dark:bg-gray-800">
      <div class="mx-auto max-w-screen-xl text-center">
        <Branding.logo />
        <p class="my-6 text-gray-500 dark:text-gray-400">
          <%= gettext("Spend more time with your patients and less time on paperwork.") %>
        </p>
        <%!-- <ul class="flex flex-wrap justify-center items-center mb-6 text-gray-900 dark:text-white">
          <li>
            <a href="#" class="mr-4 hover:underline md:mr-6 ">About</a>
          </li>
          <li>
            <a href="#" class="mr-4 hover:underline md:mr-6">Premium</a>
          </li>
          <li>
            <a href="#" class="mr-4 hover:underline md:mr-6 ">Campaigns</a>
          </li>
          <li>
            <a href="#" class="mr-4 hover:underline md:mr-6">Blog</a>
          </li>
          <li>
            <a href="#" class="mr-4 hover:underline md:mr-6">Affiliate Program</a>
          </li>
          <li>
            <a href="#" class="mr-4 hover:underline md:mr-6">FAQs</a>
          </li>
          <li>
            <a href="#" class="mr-4 hover:underline md:mr-6">Contact</a>
          </li>
        </ul> --%>
        <span class="text-sm text-gray-500 sm:text-center dark:text-gray-400">
          <%!-- © 2021-2022 <a href="#" class="hover:underline">Flowbite™</a>. All Rights Reserved. --%>
        </span>
      </div>
    </footer>
    """
  end

  defp microphone_icon(assigns) do
    ~H"""
    <svg
      class="mx-auto mb-4 w-12 h-12 text-blue-600 dark:text-blue-500"
      fill="currentColor"
      viewBox="0 0 24 24"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M12 14a3.5 3.5 0 0 0 3.5-3.5v-5a3.5 3.5 0 0 0-7 0v5A3.5 3.5 0 0 0 12 14zm7-3.5a1 1 0 0 0-2 0 5.5 5.5 0 0 1-11 0 1 1 0 0 0-2 0 7.5 7.5 0 0 0 6.5 7.45V20H8a1 1 0 1 0 0 2h8a1 1 0 1 0 0-2h-2.5v-2.05A7.5 7.5 0 0 0 19 10.5z" />
    </svg>
    """
  end

  # defp chevron_right_icon(assigns) do
  #   ~H"""
  #   <svg
  #     class="ml-1 w-5 h-5"
  #     fill="currentColor"
  #     viewBox="0 0 20 20"
  #     xmlns="http://www.w3.org/2000/svg"
  #   >
  #     <path
  #       fill-rule="evenodd"
  #       d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
  #       clip-rule="evenodd"
  #     >
  #     </path>
  #   </svg>
  #   """
  # end

  defp ambiantcare_icon(assigns) do
    ~H"""
    <svg
      class="mx-auto mb-4 w-12 h-12 text-blue-600 dark:text-blue-500"
      fill="currentColor"
      viewBox="0 0 20 20"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z"></path>
      <path
        fill-rule="evenodd"
        d="M4 5a2 2 0 012-2 3 3 0 003 3h2a3 3 0 003-3 2 2 0 012 2v11a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 4a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3zm-3 4a1 1 0 100 2h.01a1 1 0 100-2H7zm3 0a1 1 0 100 2h3a1 1 0 100-2h-3z"
        clip-rule="evenodd"
      >
      </path>
    </svg>
    """
  end

  defp approval_check_icon(assigns) do
    ~H"""
    <svg
      class="mx-auto mb-4 w-12 h-12 text-blue-600 dark:text-blue-500"
      fill="currentColor"
      viewBox="0 0 20 20"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        fill-rule="evenodd"
        d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.643.304 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
        clip-rule="evenodd"
      >
      </path>
    </svg>
    """
  end

  # defp self_served_demo_cta(assigns), do: ~H""

  # defp self_served_demo_cta(assigns) do
  #   consultations_path =
  #     AmbiantcareWeb.Gettext
  #     |> Gettext.get_locale()
  #     |> consultations_path()

  #   assigns =
  #     assigns
  #     |> assign(consultations_path: consultations_path)

  #   ~H"""
  #   <.link
  #     href={@consultations_path}
  #     target="_blank"
  #     class="text-white bg-blue-600 hover:bg-blue-700 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-3 mr-2 dark:bg-blue-600 dark:hover:bg-blue-600 focus:outline-none dark:focus:ring-blue-800"
  #   >
  #     <%= gettext("Try for free") %>
  #   </.link>
  #   """
  # end

  defp waitlist_signup_cta(assigns) do
    ~H"""
    <.link
      href="#waitlist"
      class="text-white bg-blue-600 hover:bg-blue-700 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-3 mr-2 dark:bg-blue-600 dark:hover:bg-blue-600 focus:outline-none dark:focus:ring-blue-800"
    >
      <%= gettext("Sign up for the waitlist") %>
    </.link>
    """
  end

  attr :class, :string, default: ""

  defp guided_demo_cta(assigns) do
    ~H"""
    <a
      href="https://zcal.co/luigiespasianomd/ambiant"
      target="_blank"
      class={[
        "px-5 py-3 text-base font-medium text-center text-gray-900 border border-gray-300 rounded-lg hover:bg-gray-100 focus:ring-4 focus:ring-gray-100 dark:text-white dark:border-gray-700 dark:hover:bg-gray-700 dark:focus:ring-gray-800",
        @class
      ]}
    >
      <%= gettext("Book a demo") %>
    </a>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("submit_waitlist_user_entry", %{} = attrs, socket) do
    attrs = Map.new(attrs, fn {k, v} -> {k, String.trim(v)} end)

    socket =
      case Waitlists.get_or_insert_user_entry(attrs) do
        {:ok, %UserEntry{}} ->
          put_flash(socket, :info, gettext("You have been added to the waitlist!"))

        {:error, %Changeset{} = changeset} ->
          reason = inspect(changeset.errors)

          message =
            dgettext("errors", "Failed to register for the waitlist: %{reason}", reason: reason)

          put_flash(socket, :error, message)
      end

    {:noreply, socket}
  end
end
