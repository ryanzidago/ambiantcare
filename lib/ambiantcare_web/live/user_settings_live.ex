defmodule AmbiantcareWeb.UserSettingsLive do
  use AmbiantcareWeb, :live_view
  use Gettext, backend: AmbiantcareWeb.Gettext

  alias Ambiantcare.Accounts
  alias Ambiantcare.MedicalNotes.Templates
  alias Ambiantcare.MedicalNotes.Template

  alias AmbiantcareWeb.Components.Branding
  alias AmbiantcareWeb.Components.Shell

  alias Ecto.Changeset

  def render(assigns) do
    ~H"""
    <Shell.with_sidebar>
      <:sidebar>
        <.sidebar current_user={@current_user} locale={@locale} />
      </:sidebar>
      <:main>
        <.settings
          current_user={@current_user}
          current_email={@current_email}
          current_password={@current_password}
          email_form={@email_form}
          email_form_current_password={@email_form_current_password}
          password_form={@password_form}
          locale={@locale}
          trigger_submit={@trigger_submit}
          default_medical_note_template_form={@default_medical_note_template_form}
          default_medical_note_template={@default_medical_note_template}
          medical_note_template_options={@medical_note_template_options}
        />
      </:main>
    </Shell.with_sidebar>
    """
  end

  defp settings(assigns) do
    ~H"""
    <div>
      <.header class="text-center">
        <%= gettext("Account Settings") %>
        <:subtitle>
          <%= gettext("Manage your account, email address and password settings") %>
        </:subtitle>
      </.header>

      <div class="space-y-12 divide-y">
        <div>
          <.simple_form
            for={@default_medical_note_template_form}
            id="default_medical_note_template_form"
            phx-change="change_default_medical_note_template_form"
          >
            <.input
              type="select"
              field={@default_medical_note_template_form[:default_medical_note_template_id]}
              options={@medical_note_template_options}
              label={gettext("Select default template")}
            />
          </.simple_form>
        </div>
        <div>
          <.simple_form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
          >
            <.input field={@email_form[:email]} type="email" label="Email" required />
            <.input
              field={@email_form[:current_password]}
              name="current_password"
              id="current_password_for_email"
              type="password"
              label={gettext("Current password")}
              value={@email_form_current_password}
              required
            />
            <:actions>
              <.button phx-disable-with={gettext("Changing...")}>
                <%= gettext("Change Email") %>
              </.button>
            </:actions>
          </.simple_form>
        </div>
        <div>
          <.simple_form
            for={@password_form}
            id="password_form"
            action={~p"/#{@locale}/users/log_in?_action=password_updated"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              value={@current_email}
            />
            <.input
              field={@password_form[:password]}
              type="password"
              label={gettext("New password")}
              required
            />
            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label={gettext("Confirm new password")}
            />
            <.input
              field={@password_form[:current_password]}
              name="current_password"
              type="password"
              label="Current password"
              id="current_password_for_password"
              value={@current_password}
              required
            />
            <:actions>
              <.button phx-disable-with={gettext("Changing...")}>
                <%= gettext("Change Password") %>
              </.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  defp sidebar(assigns) do
    ~H"""
    <div class="flex flex-col justify-between h-full">
      <Branding.logo class="py-14" />
      <ul class="flex flex-col items-start gap-4 p-4 sm:px-6 lg:px-8 align-bottom justify-end border">
        <%= if @current_user do %>
          <li class="text-[0.8125rem] text-zinc-900">
            <%= @current_user.email %>
          </li>
          <li>
            <.link
              phx-click="toggle_action_panel"
              phx-value-action="medical_notes"
              class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
            >
              <%= gettext("Medical Notes") %>
            </.link>
          </li>
          <li>
            <.link
              href={~p"/#{@locale}/users/log_out"}
              method="delete"
              class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
            >
              <%= gettext("Log out") %>
            </.link>
          </li>
        <% else %>
          <li>
            <.link
              href={~p"/#{@locale}/users/register"}
              class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
            >
              <%= gettext("Register") %>
            </.link>
          </li>
          <li>
            <.link
              href={~p"/#{@locale}/users/log_in"}
              class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
            >
              <%= gettext("Log in") %>
            </.link>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    locale = Gettext.get_locale(AmbiantcareWeb.Gettext)

    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, gettext("Email changed successfully."))

        :error ->
          put_flash(socket, :error, gettext("Email change link is invalid or it has expired."))
      end

    {:ok, push_navigate(socket, to: ~p"/#{locale}/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(current_user: user)
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(default_medical_note_template_form: to_form(%{}))
      |> assign(:trigger_submit, false)
      |> assign_medical_note_templates()
      |> assign_default_medical_note_template()
      |> assign_medical_note_template_options()

    {:ok, socket}
  end

  defp assign_medical_note_templates(socket) do
    current_user = socket.assigns.current_user
    templates = Templates.templates(current_user)

    assign(socket, medical_note_templates: templates)
  end

  defp assign_default_medical_note_template(socket) do
    default_template = Enum.find(socket.assigns.medical_note_templates, & &1.is_default)

    assign(socket, default_medical_note_template: default_template)
  end

  defp assign_medical_note_template_options(socket) do
    options = Enum.map(socket.assigns.medical_note_templates, &{&1.title, &1.id})

    assign(socket, medical_note_template_options: options)
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user
    locale = Gettext.get_locale(AmbiantcareWeb.Gettext)

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/#{locale}/users/settings/confirm_email/#{&1}")
        )

        info = gettext("A link to confirm your email change has been sent to the new address.")
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("toggle_action_panel", %{"action" => "medical_notes"}, socket) do
    path = AmbiantcareWeb.Utils.PathUtils.consultations_path(socket.assigns.locale)
    {:noreply, push_navigate(socket, to: path)}
  end

  def handle_event(
        "change_default_medical_note_template_form",
        %{"default_medical_note_template_id" => template_id},
        socket
      ) do
    current_user = socket.assigns.current_user
    previous_default_template = Enum.find(socket.assigns.medical_note_templates, & &1.is_default)
    template = Enum.find(socket.assigns.medical_note_templates, &(&1.id == template_id))

    result =
      Templates.update_user_default_template(
        current_user,
        previous_default_template,
        template
      )

    socket =
      case result do
        {:ok, %{default_template: %Template{}}} ->
          socket
          |> put_flash(:info, gettext("Default template sucessfully updated"))
          |> assign_medical_note_templates()
          |> assign_default_medical_note_template()
          |> assign_medical_note_template_options()

        {:error, %Changeset{} = changeset} ->
          message =
            dgettext("errors", "Failed to update default template: %{reason}",
              reason: changeset.errors
            )

          put_flash(socket, :error, message)
      end

    {:noreply, socket}
  end
end
