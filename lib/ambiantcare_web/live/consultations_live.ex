defmodule AmbiantcareWeb.ConsultationsLive do
  @doc """
  LiveView managing the medical notes form and visit recording.
  """
  use AmbiantcareWeb, :live_view

  use Gettext, backend: AmbiantcareWeb.Gettext

  require Logger

  alias Phoenix.LiveView
  alias Phoenix.LiveView.AsyncResult
  alias Phoenix.LiveView.UploadEntry
  alias Ecto.Changeset

  alias Ambiantcare.MedicalNotes.Template
  alias Ambiantcare.MedicalNotes.MedicalNote
  alias Ambiantcare.MedicalNotes.Prompts
  alias Ambiantcare.Audio
  alias Ambiantcare.Accounts
  alias Ambiantcare.Consultations
  alias Ambiantcare.Consultations.Consultation
  alias Ambiantcare.Cldr

  alias Ambiantcare.AI.HuggingFace
  alias Ambiantcare.AI.Gladia
  alias Ambiantcare.AI.SpeechMatics

  alias AmbiantcareWeb.Microphone
  alias AmbiantcareWeb.Hooks.SetLocale
  alias AmbiantcareWeb.Components.Branding
  alias AmbiantcareWeb.Components.Shell
  alias AmbiantcareWeb.Utils.PathUtils

  import Ecto.Changeset
  import AmbiantcareWeb.ConsultationsLive.Helpers

  @impl LiveView
  def mount(params, session, socket) do
    socket =
      socket
      |> assign(session: session)
      |> assign_current_user(session)
      |> assign_consultations()
      |> assign_consultation(params)
      # @ryanzidago - refactor this to avoid derived state
      |> assign_consultation_transcription()
      |> assign_speech_to_text_backend(params)
      |> assign_huggingface_deployment(params)
      |> assign_templates_by_id()
      |> assign_selected_template()
      |> assign(recording?: false)
      |> assign(consultation_transcription_loading: false)
      |> assign(visit_context: %AsyncResult{ok?: true, loading: false, result: nil})
      |> assign_medical_note_changeset(params)
      |> assign(medical_note_loading: false)
      |> assign(microphone_hook: Microphone.from_params(params))
      |> assign(url_params: params)
      |> assign(current_action: "transcription")
      |> assign(upload_type: :from_user_microphone)
      |> assign(selected_pre_recorded_audio_file: nil)
      |> allow_upload(:audio_from_user_microphone,
        accept: :any,
        progress: &process_audio/3,
        auto_upload: true,
        max_entries: 10,
        max_file_size: 100_000_000
      )
      |> allow_upload(:audio_from_user_file_system,
        accept: ~w(.mp3 .flac),
        progress: &process_audio/3,
        auto_upload: true,
        max_file_size: 100_000_000
      )
      |> maybe_resume_dedicated_endpoint()

    log_values(socket)

    {:ok, socket}
  end

  @impl LiveView
  def render(assigns) do
    ~H"""
    <Shell.with_sidebar {assigns}>
      <:sidebar>
        <.sidebar current_user={@current_user} locale={@locale} consultations={@consultations} />
      </:sidebar>
      <:main>
        <.action_panel
          current_action={@current_action}
          consultation_transcription={@consultation_transcription}
          consultation_transcription_loading={@consultation_transcription_loading}
          visit_context={@visit_context}
          medical_note_loading={@medical_note_loading}
          uploads={@uploads}
          upload_type={@upload_type}
          microphone_hook={@microphone_hook}
          recording?={@recording?}
          selected_pre_recorded_audio_file={@selected_pre_recorded_audio_file}
          medical_note_changeset={@medical_note_changeset}
          selected_template={@selected_template}
        />
      </:main>
    </Shell.with_sidebar>
    """
  end

  defp sidebar(assigns) do
    assigns =
      assigns
      |> assign(
        consultations_by_date:
          assigns.consultations
          |> Enum.group_by(fn
            consultation when is_nil(consultation.start_datetime) ->
              nil

            consultation ->
              DateTime.to_date(consultation.start_datetime)
          end)
          |> Enum.sort_by(
            fn {grouping_key, _consultations} -> grouping_key || Date.utc_today() end,
            {:desc, Date}
          )
      )

    ~H"""
    <div class="flex flex-col h-screen w-full text-sm">
      <Branding.logo class="py-14" />
      <.new_consultation_button />
      <div class="flex flex-col items-start gap-6 sm:px-6 lg:px-8 overflow-auto">
        <div
          :for={{grouping_key, consultations} <- @consultations_by_date}
          :if={Enum.any?(@consultations)}
          class="flex flex-col w-full gap-1 p-2"
        >
          <span class="p-1"><%= consultations_group_label(grouping_key) %></span>
          <.link
            :for={consultation <- consultations}
            phx-click="navigate_to_consultation"
            phx-value-consultation_id={consultation.id}
            class="flex flex-row items-center gap-2 justify-between hover:bg-gray-200 hover:font-medium hover:text-blue-700 focus:text-blue-700 hover:shadow-xs p-1 rounded focus:bg-gray-200 focus:font-medium transition-all transform duration-200"
          >
            <span class=""><%= consultation.label %></span>
            <span class="text-xs hover:font-medium">
              <%= grouping_key && consultation_start_datetime_label(consultation.start_datetime) %>
            </span>
          </.link>
        </div>
      </div>
      <ul class="flex flex-col items-start gap-4 p-4 sm:px-6 lg:px-8 align-bottom justify-end border mt-10">
        <%= if @current_user do %>
          <li class="text-[0.8125rem] text-zinc-900">
            <%= @current_user.email %>
          </li>
          <li>
            <.link
              phx-click="toggle_action_panel"
              phx-value-action="settings"
              class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
            >
              <%= gettext("Settings") %>
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

  defp new_consultation_button(assigns) do
    ~H"""
    <.button type="button" phx-click="new_consultation" class="mx-10 mb-10">
      <%= gettext("New consultation") %>
    </.button>
    """
  end

  defp consultations_group_label(nil), do: gettext("Not started")

  defp consultations_group_label(%Date{} = date) do
    locale = Gettext.get_locale(AmbiantcareWeb.Gettext)

    cond do
      today_or_yesterday?(date) ->
        today = Date.utc_today()

        Date.diff(date, today)
        |> Cldr.DateTime.Relative.to_string!(unit: :day, locale: locale)
        |> String.capitalize()

      in_current_week?(date) ->
        date
        |> Cldr.Date.to_string!(format: "EEEE", locale: locale)
        |> String.capitalize()

      true ->
        date
        |> Cldr.Date.to_string!(format: :short, locale: locale)
    end
  end

  defp today_or_yesterday?(date) do
    today = Date.utc_today()
    Date.diff(date, today) in -1..0
  end

  defp in_current_week?(date) do
    today = Date.utc_today()
    beginning_of_week = Date.beginning_of_week(today)
    range = Date.range(beginning_of_week, today)
    date in range
  end

  defp consultation_start_datetime_label(nil),
    do: consultation_start_datetime_label(DateTime.utc_now())

  defp consultation_start_datetime_label(%DateTime{} = start_datetime) do
    Cldr.Time.to_string!(start_datetime,
      format: :short,
      locale: Gettext.get_locale(AmbiantcareWeb.Gettext)
    )
  end

  defp action_panel(assigns)
       when assigns.current_action in ~w(transcription visit_context medical_note consultation_settings) do
    assigns =
      assign(assigns,
        action_panel_items: [
          {"transcription", gettext("Transcription")},
          {"visit_context", gettext("Context")},
          {"medical_note", gettext("Medical Note")},
          {"consultation_settings", gettext("Settings")}
        ]
      )

    ~H"""
    <div class="flex flex-col gap-10">
      <ul class="flex flex-wrap text-sm font-medium text-center text-gray-500 border-b border-gray-200 dark:border-gray-700 dark:text-gray-400">
        <li
          :for={{action, label} <- @action_panel_items}
          class={[
            "rounded-none",
            "first:rounded-l-lg",
            "last:rounded-r-lg"
          ]}
        >
          <.link
            class={[
              "inline-block p-4 rounded-t-lg hover:text-gray-600 hover:bg-gray-50 dark:hover:bg-gray-800 dark:hover:text-gray-300 focus:text-blue-600",
              if(action == @current_action,
                do: "text-blue-600 bg-gray-100 dark:bg-gray-800 dark:text-blue-500 shadow-sm"
              )
            ]}
            phx-click="toggle_action_panel"
            phx-value-action={action}
          >
            <%= label %>
          </.link>
        </li>
      </ul>
      <.action_panel_item {assigns} />
    </div>
    """
  end

  defp action_panel_item(assigns) when assigns.current_action == "transcription" do
    ~H"""
    <.transcription_panel
      consultation_transcription={@consultation_transcription}
      consultation_transcription_loading={@consultation_transcription_loading}
      medical_note_loading={@medical_note_loading}
      uploads={@uploads}
      upload_type={@upload_type}
      microphone_hook={@microphone_hook}
      recording?={@recording?}
      selected_pre_recorded_audio_file={@selected_pre_recorded_audio_file}
    />
    """
  end

  defp action_panel_item(assigns) when assigns.current_action == "visit_context" do
    ~H"""
    <.consultation_panel visit_context={@visit_context} />
    """
  end

  defp action_panel_item(assigns) when assigns.current_action == "medical_note" do
    ~H"""
    <.medical_note
      medical_note_changeset={@medical_note_changeset}
      selected_template={@selected_template}
    />
    """
  end

  defp action_panel_item(assigns) when assigns.current_action == "consultation_settings" do
    ~H"""
    <.consultation_settings_panel />
    """
  end

  defp transcription_panel(assigns) do
    ~H"""
    <div class="flex flex-col gap-10">
      <.recording_button
        recording?={@recording?}
        microphone_hook={@microphone_hook}
        consultation_transcription_loading={@consultation_transcription_loading}
        uploads={@uploads}
        upload_type={@upload_type}
        selected_pre_recorded_audio_file={@selected_pre_recorded_audio_file}
      />

      <div class="flex flex-col">
        <.async_result :let={consultation_transcription} assign={@consultation_transcription}>
          <:failed :let={_reason}>
            <span class="flex flex-col items-center">Oops, something went wrong!</span>
          </:failed>
          <.consultation_transcription
            consultation_transcription={consultation_transcription}
            medical_note_loading={@medical_note_loading}
          />
        </.async_result>
      </div>
    </div>
    """
  end

  attr :visit_context, :string, required: true

  defp consultation_panel(assigns) do
    ~H"""
    <div class="flex flex-col gap-10">
      <div class="flex flex-col">
        <.async_result :let={visit_context} assign={@visit_context}>
          <:loading>
            <div class="flex flex-col items-center">
              <.spinner />
            </div>
          </:loading>
          <:failed :let={_reason}>
            <span class="flex flex-col items-center">Oops, something went wrong!</span>
          </:failed>
          <quote class="text-sm">
            <.form for={%{}} class="drop-shadow-sm" phx-change="change_visit_context">
              <div class="w-full flex flex-col gap-10">
                <.input
                  type="textarea"
                  value={visit_context}
                  name="visit_context"
                  label={gettext("Consultation Context")}
                  placeholder={gettext("Provide additional context about the patient.")}
                  input_class="h-[50vh]"
                />
              </div>
            </.form>
          </quote>
        </.async_result>
      </div>
    </div>
    """
  end

  defp consultation_settings_panel(assigns) do
    ~H"""
    <.button
      type="button"
      variant={:danger}
      phx-click="delete_consultation"
      class="md:min-w-32 max-w-52"
    >
      <%= gettext("Delete consultation") %>
    </.button>
    """
  end

  attr :recording?, :boolean, required: true
  attr :microphone_hook, :string, required: true
  attr :consultation_transcription_loading, :boolean, required: true
  attr :uploads, :any, required: true
  attr :upload_type, :atom, default: nil
  attr :selected_pre_recorded_audio_file, :string, default: nil

  defp recording_button(assigns) do
    ~H"""
    <form phx-change="no_op" phx-submit="no_op" class="hidden">
      <.live_file_input upload={@uploads.audio_from_user_microphone} />
    </form>

    <div class="flex flex-row items-center gap-4">
      <div class="flex">
        <.button
          type="button"
          id="microphone"
          phx-hook={@microphone_hook}
          data-endianness={System.endianness()}
          class="md:min-w-32"
        >
          <span :if={not @recording?}>
            <%= gettext("Start Consultation") %>
          </span>

          <span :if={@recording?}>
            <%= gettext("End Consultation") %>
          </span>
        </.button>

        <button
          :if={not @recording?}
          type="button"
          class="transition-all transform duration-200 hover:scale-110"
          phx-click={show_modal("audio-input-options-modal")}
        >
          <.icon name="flowbite-breadcrumbs" />
        </button>
      </div>

      <.start_visit_alternatives_modal
        uploads={@uploads}
        upload_type={@upload_type}
        selected_pre_recorded_audio_file={@selected_pre_recorded_audio_file}
      />

      <div :if={@recording?} class="flex flex-row items-center justify-center gap-4 animate-pulse">
        <div class="w-3 h-3 rounded-full bg-red-600"></div>
        <%= gettext("Recording") %>
      </div>

      <.upload_progress_bar entries={@uploads.audio_from_user_file_system.entries} />

      <div
        :if={@consultation_transcription_loading}
        class="flex flex-row items-center justify-center gap-4 animate-pulse"
      >
        <.spinner />
        <%= gettext("Generating the transcription ...") %>
      </div>
    </div>
    """
  end

  attr :entries, :list, required: true

  defp upload_progress_bar(assigns) do
    ~H"""
    <div :for={entry <- @entries} class="flex flex-row items-center gap-4 animate-pulse">
      <.spinner />
      <span><%= gettext("Uploading file ...") %></span>
      <progress value={entry.progress} max="100" class="rounded-sm shadow-md">
        <%= entry.progress %>%
      </progress>
    </div>
    """
  end

  defp start_visit_alternatives_modal(assigns) do
    pre_recorded_audio_files_options = [
      {gettext("Generalist 1 visit"), "/audio/generalist_1.mp3"},
      {gettext("Generalist 2 visit"), "/audio/generalist_2.mp3"}
    ]

    assigns =
      assign(assigns,
        pre_recorded_audio_files_options: Enum.sort(pre_recorded_audio_files_options)
      )

    ~H"""
    <.modal id="audio-input-options-modal">
      <div class="flex flex-col gap-10">
        <.form
          for={%{}}
          phx-change={
            %JS{}
            |> hide_modal("audio-input-options-modal")
            |> JS.push("no_op")
          }
        >
          <div class="flex flex-col gap-2">
            <.label for={@uploads.audio_from_user_file_system.ref}>
              <%= gettext("Upload an audio file from your device") %>
            </.label>
            <.live_file_input
              upload={@uploads.audio_from_user_file_system}
              phx-click="change_upload_type"
              phx-value-upload_type="from_user_file_system"
            />
          </div>
        </.form>

        <.simple_form
          for={%{}}
          phx-change="change_pre_recorded_audio_file"
          phx-submit={
            %JS{}
            |> hide_modal("audio-input-options-modal")
            |> JS.push("submit_pre_recorded_audio_file")
          }
        >
          <.input
            label={gettext("Or select one of the examples")}
            type="select"
            name="pre_recorded_audio_file"
            prompt=""
            value={@selected_pre_recorded_audio_file}
            options={@pre_recorded_audio_files_options}
            class="shadow"
          />
          <audio
            :if={@selected_pre_recorded_audio_file}
            id={"audio-controls-#{@selected_pre_recorded_audio_file}"}
            controls
            class="rounded-md shadow"
          >
            <source src={@selected_pre_recorded_audio_file} type="audio/mpeg" />
            <%= gettext("Your browser does not support the audio element.") %>
          </audio>
          <:actions>
            <.button type="submit" disabled={is_nil(@selected_pre_recorded_audio_file)}>
              <%= gettext("Save") %>
            </.button>
            <.button
              type="button"
              phx-click={
                %JS{}
                |> hide_modal("audio-input-options-modal")
                |> JS.push(
                  "change_pre_recorded_audio_file",
                  value: %{"pre_recorded_audio_file" => ""}
                )
              }
            >
              <%= gettext("Cancel") %>
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </.modal>
    """
  end

  defp medical_note(assigns) do
    current_datetime =
      (DateTime.utc_now()
       |> DateTime.truncate(:second)
       |> DateTime.to_string()
       |> String.replace("Z", "")) <> " UTC"

    medical_note_text = to_text(assigns.medical_note_changeset, current_datetime)

    assigns =
      assigns
      |> assign(current_datetime: current_datetime)
      |> assign(medical_note_text: medical_note_text)

    ~H"""
    <.async_result :let={changeset} assign={@medical_note_changeset}>
      <:failed :let={_reason}>
        <%= gettext("Oops, something went wrong!") %>
      </:failed>
      <.form :let={form} for={changeset} class="flex flex-col gap-10 drop-shadow-sm">
        <.inputs_for :let={field} field={form[:fields]}>
          <.field field={field} selected_template={@selected_template} />
        </.inputs_for>

        <div class="flex flex-row gap-10">
          <.button
            type="button"
            class="md:min-w-32"
            phx-click={
              JS.dispatch("phx:download",
                detail: %{
                  data: @medical_note_text,
                  filename: "medical_note_#{@current_datetime}.txt",
                  type: "text/plain"
                }
              )
            }
          >
            <%= gettext("Download") %>
          </.button>
          <.button
            type="button"
            class="md:min-w-32"
            phx-click={
              JS.dispatch("phx:copy",
                detail: %{
                  text: @medical_note_text
                }
              )
            }
          >
            <%= gettext("Copy") %>
          </.button>
        </div>
      </.form>
    </.async_result>
    """
  end

  defp field(assigns) do
    name = fetch_field!(assigns.field.source, :name)
    value = fetch_field!(assigns.field.source, :value)

    template_fields = assigns.selected_template.fields
    template_fields_by_name = Map.new(template_fields, fn field -> {field.name, field} end)
    template_field = Map.fetch!(template_fields_by_name, name)

    assigns =
      assigns
      |> assign(input_type: Atom.to_string(template_field.input_type))
      |> assign(name: name)
      |> assign(label: template_field.label)
      |> assign(value: value)

    ~H"""
    <.input type={@input_type} name={@name} label={@label} value={@value} />
    """
  end

  attr :consultation_transcription, :string, required: true
  attr :medical_note_loading, :boolean, required: true

  defp consultation_transcription(assigns) do
    ~H"""
    <.form
      for={%{}}
      class="drop-shadow-sm text-sm"
      phx-change="change_consultation_transcription"
      phx-submit="generate_medical_note"
    >
      <div class="w-full flex flex-col gap-10">
        <.input
          type="textarea"
          value={@consultation_transcription}
          name="consultation_transcription"
          label={gettext("Consultation Transcription")}
          input_class="h-[50vh]"
        />
        <div class="flex flex-row gap-10">
          <.button :if={not @medical_note_loading} type="submit" class="md:min-w-32">
            <%= gettext("Create note") %>
          </.button>
          <.button
            :if={@medical_note_loading}
            type="button"
            class="md:min-w-32 animate-pulse"
            disabled
          >
            <.spinner />
            <%= gettext("Generating note ...") %>
          </.button>
          <.button
            type="button"
            class="md:min-w-32"
            phx-click={
              JS.dispatch("phx:download",
                detail: %{
                  data: @consultation_transcription,
                  filename: "transcription.txt",
                  type: "text/plain"
                }
              )
            }
          >
            <%= gettext("Download") %>
          </.button>
          <.button
            type="button"
            class="md:min-w-32 text-white"
            phx-click={
              JS.dispatch("phx:copy",
                detail: %{
                  text: @consultation_transcription
                }
              )
            }
          >
            <%= gettext("Copy") %>
          </.button>
        </div>
      </div>
    </.form>
    """
  end

  @impl LiveView
  def handle_event("start_recording", _, socket) do
    socket = assign(socket, recording?: true)
    {:noreply, socket}
  end

  def handle_event("stop_recording", _, socket) do
    socket = assign(socket, recording?: false)
    {:noreply, socket}
  end

  def handle_event("change_template", %{"template_id" => template_id}, socket) do
    template = Map.fetch!(socket.assigns.templates_by_id, template_id)

    medical_note_changeset =
      %AsyncResult{
        ok?: true,
        loading: false,
        result:
          template
          |> MedicalNote.from_template()
          |> MedicalNote.changeset(%{})
      }

    socket =
      socket
      |> assign(selected_template: template)
      |> assign(medical_note_changeset: medical_note_changeset)

    {:noreply, socket}
  end

  def handle_event("change_medical_note", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("change_locale", %{"locale" => locale}, socket) do
    socket = SetLocale.set(socket, locale, "/consultations")
    {:noreply, socket}
  end

  def handle_event("toggle_action_panel", %{"action" => "settings"}, socket) do
    {:noreply, push_navigate(socket, to: "/#{socket.assigns.locale}/users/settings")}
  end

  def handle_event("toggle_action_panel", %{"action" => action}, socket) do
    {:noreply, assign(socket, current_action: action)}
  end

  def handle_event("change_visit_context", %{"visit_context" => context}, socket) do
    Logger.debug("Consultation context changed to: #{context}")

    socket =
      assign(socket,
        visit_context: %AsyncResult{ok?: true, loading: false, result: context}
      )

    {:noreply, socket}
  end

  def handle_event("change_upload_type", %{"upload_type" => upload_type}, socket) do
    upload_type =
      case upload_type do
        "from_user_microphone" -> :from_user_microphone
        "from_user_file_system" -> :from_user_file_system
      end

    {:noreply, assign(socket, upload_type: upload_type)}
  end

  def handle_event("no_op", _params, socket) do
    # We need phx-change and phx-submit on the form for live uploads,
    # but we make predictions immediately using :progress, so we just
    # ignore this event
    {:noreply, socket}
  end

  def handle_event("change_pre_recorded_audio_file", %{"pre_recorded_audio_file" => ""}, socket) do
    socket =
      socket
      |> assign(selected_pre_recorded_audio_file: nil)
      |> assign(upload_type: :from_user_microphone)

    {:noreply, socket}
  end

  def handle_event(
        "change_pre_recorded_audio_file",
        %{"pre_recorded_audio_file" => pre_recorded_audio_file} = _params,
        socket
      ) do
    socket =
      socket
      |> assign(selected_pre_recorded_audio_file: pre_recorded_audio_file)
      |> assign(upload_type: :from_user_file_system)

    {:noreply, socket}
  end

  def handle_event(
        "submit_pre_recorded_audio_file",
        %{"pre_recorded_audio_file" => pre_recorded_audio_file},
        socket
      ) do
    socket =
      socket
      |> assign(selected_pre_recorded_audio_file: nil)
      |> assign(upload_type: :from_user_file_system)

    {:noreply, _socket} =
      process_audio(:audio_from_user_file_system, pre_recorded_audio_file, socket)
  end

  def handle_event(
        "change_consultation_transcription",
        %{"consultation_transcription" => consultation_transcription},
        socket
      ) do
    consultation_transcription = %AsyncResult{
      ok?: true,
      loading: false,
      result: consultation_transcription
    }

    socket = assign(socket, consultation_transcription: consultation_transcription)
    {:noreply, socket}
  end

  def handle_event(
        "generate_medical_note",
        %{"consultation_transcription" => consultation_transcription},
        socket
      ) do
    selected_template = socket.assigns.selected_template
    context = socket.assigns.visit_context.result

    params = %{
      context: context,
      transcription: consultation_transcription,
      template: selected_template
    }

    socket =
      socket
      |> assign(medical_note_loading: true)
      |> start_async(:generate_medical_note, fn -> query_llm(params) end)

    {:noreply, socket}
  end

  def handle_event("new_consultation", _params, socket) do
    user = socket.assigns.current_user
    consultation = %Consultation{}

    attrs = %{
      user_id: user.id,
      label: Consultation.default_label()
    }

    socket =
      case Consultations.create_or_update_consultation(user, consultation, attrs) do
        {:ok, %Consultation{} = consultation} ->
          push_navigate(socket, to: PathUtils.consultation_path(consultation))

        {:error, %Changeset{} = changeset} ->
          message =
            gettext("Failed to create a new consultation: %{reason}",
              reason: inspect(changeset.errors)
            )

          put_flash(socket, :error, message)
      end

    {:noreply, socket}
  end

  def handle_event("navigate_to_consultation", _params, socket) do
    consultation = socket.assigns.consultation
    socket = push_navigate(socket, to: PathUtils.consultation_path(consultation))
    {:noreply, socket}
  end

  def handle_event("delete_consultation", _params, socket) do
    consultation = socket.assigns.consultation
    user = socket.assigns.current_user

    socket =
      case Consultations.delete_consultation(user, consultation) do
        {:ok, _} ->
          socket
          |> put_flash(:info, gettext("Consultation successfully deleted"))
          |> push_navigate(to: PathUtils.consultations_path())

        {:error, %Changeset{} = changeset} ->
          reason = inspect(changeset.errors)

          message =
            dgettext("errors", "Failed to delete the consultation: %{reason}", reason: reason)

          put_flash(socket, :error, message)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:error, reason}, socket) do
    Logger.error(reason)
    {:noreply, socket}
  end

  @impl true
  def handle_async(:audio_to_structured_text, {:ok, {:ok, result}}, socket) do
    current_user = socket.assigns.current_user
    consultation = socket.assigns.consultation
    consultation_transcription = result.consultation_transcription
    medical_note_changeset = result.medical_note_changeset

    attrs = %{
      label: consultation.label,
      transcription: consultation_transcription,
      user_id: current_user.id,
      end_datetime: DateTime.utc_now()
    }

    socket =
      case Consultations.create_or_update_consultation(current_user, consultation, attrs) do
        {:ok, %Consultation{} = consultation} ->
          push_navigate(socket, to: PathUtils.consultation_path(consultation))

        {:error, %Changeset{} = changeset} ->
          reason = inspect(changeset.errors)

          message =
            dgettext("errors", "Failed to save the consultation: %{reason}", reason: reason)

          socket
          |> put_flash(:error, message)
          |> assign(consultation_transcription_loading: false)
      end

    socket =
      socket
      |> assign(consultation_transcription_loading: false)
      |> assign(consultation_transcription: AsyncResult.ok(consultation_transcription))
      |> assign(medical_note_changeset: AsyncResult.ok(medical_note_changeset))

    {:noreply, socket}
  end

  def handle_async(
        :generate_medical_note,
        {:ok, {:ok, %Changeset{} = medical_note_changeset}},
        socket
      ) do
    socket =
      socket
      |> assign(medical_note_loading: false)
      |> assign(medical_note_changeset: AsyncResult.ok(medical_note_changeset))

    {:noreply, socket}
  end

  def handle_async(task, {:ok, {:error, error}}, socket) do
    error = gettext("Task %{task} failed with error: %{error}", task: task, error: error)
    socket = put_flash(socket, :error, error)
    {:noreply, socket}
  end

  defp process_audio(:audio_from_user_file_system, filename, socket) when is_binary(filename) do
    filename = Path.join(static_dir(), filename)
    binary = File.read!(filename)

    process_audio(filename, binary, socket)
  end

  defp process_audio(:audio_from_user_file_system, %UploadEntry{} = entry, socket)
       when entry.done? do
    filename = entry.client_name
    binary = consume_uploaded_entry(socket, entry, fn %{path: path} -> File.read(path) end)
    process_audio(filename, binary, socket)
  end

  defp process_audio(:audio_from_user_microphone, %UploadEntry{} = entry, socket)
       when entry.done? do
    filename = entry.client_name
    binary = consume_uploaded_entry(socket, entry, fn %{path: path} -> File.read(path) end)
    process_audio(filename, binary, socket)
  end

  defp process_audio(filename, binary, %{} = socket)
       when is_binary(filename) and is_binary(binary) do
    microphone_hook = Map.fetch!(socket.assigns, :microphone_hook)
    current_consultation_transcription = get_current_transcription(socket)
    stt_backend = socket.assigns.stt_backend
    selected_template = socket.assigns.selected_template
    context = socket.assigns.visit_context.result
    upload_type = socket.assigns.upload_type

    stt_params =
      %{}
      |> Map.put(:stt_backend, stt_backend)
      |> Map.put(:use_local_stt?, use_local_stt?())
      |> Map.merge(Enum.into(backend_opts(stt_backend, socket.assigns), %{}))

    upload_metadata =
      %{}
      |> Map.put(:binary, binary)
      |> Map.put(:upload_type, upload_type)
      |> Map.put(:client_filename, filename)
      |> Map.put(:microphone_hook, microphone_hook)

    context_params =
      %{}
      |> Map.put(:transcription, current_consultation_transcription)
      |> Map.put(:template, selected_template)
      |> Map.put(:visit_context, context)
      |> Map.put(:locale, Gettext.get_locale(AmbiantcareWeb.Gettext))

    opts = [parent: self()]

    socket =
      socket
      |> assign(consultation_transcription_loading: true)
      |> start_async(:audio_to_structured_text, fn ->
        audio_to_structured_text(stt_params, upload_metadata, context_params, opts)
      end)

    {:noreply, socket}
  end

  defp process_audio(_key, _entry, socket) do
    {:noreply, socket}
  end

  defp assign_current_user(socket, %{"user_token" => user_token} = _session) do
    current_user = Accounts.get_user_by_session_token(user_token)
    assign(socket, current_user: current_user)
  end

  defp assign_consultations(socket) do
    current_user = socket.assigns.current_user
    consultations = Consultations.list_consultations(current_user)
    assign(socket, consultations: consultations)
  end

  defp assign_consultation(socket, %{"consultation_id" => consultation_id}) do
    current_user = socket.assigns.current_user
    consultation = Consultations.get_consultation(current_user, consultation_id)
    assign(socket, consultation: consultation)
  end

  defp assign_consultation(socket, _params) do
    current_user = socket.assigns.current_user
    consultation = Consultations.get_latest_consultation(current_user)
    assign(socket, consultation: consultation)
  end

  defp assign_consultation_transcription(%{assigns: %{consultation: %Consultation{}}} = socket) do
    consultation = socket.assigns.consultation
    transcription = %AsyncResult{ok?: true, loading: false, result: consultation.transcription}
    assign(socket, consultation_transcription: transcription)
  end

  defp assign_consultation_transcription(%{assigns: %{consultation: nil}} = socket) do
    transcription = %AsyncResult{ok?: true, loading: false, result: nil}
    assign(socket, consultation_transcription: transcription)
  end

  defp assign_huggingface_deployment(socket, params) do
    if socket.assigns.stt_backend == HuggingFace do
      assign(socket, huggingface_deployment: HuggingFace.deployment(params))
    else
      socket
    end
  end

  defp audio_to_structured_text(stt_params, upload_metadata, context_params, opts) do
    current_consultation_transcription = context_params.transcription

    with {:ok, transcription} <- transcribe_audio(stt_params, upload_metadata),
         {:ok, medical_note_changeset} <- query_llm(context_params) do
      Logger.debug("*** begin transcription ***")
      Logger.debug(transcription)
      Logger.debug("*** end transcription ***")

      transcription = current_consultation_transcription <> " " <> transcription

      {:ok,
       %{
         consultation_transcription: transcription,
         medical_note_changeset: medical_note_changeset
       }}
    else
      {:error, reason} ->
        maybe_send_to_parent(opts, {:error, reason})
        {:error, reason}
    end
  end

  defp transcribe_audio(%{} = stt_params, upload_metadata) when stt_params.use_local_stt? do
    binary = upload_metadata.binary
    upload_type = upload_metadata.upload_type

    input =
      case upload_type do
        :from_user_file_system ->
          filename = System.tmp_dir!() <> "_" <> Ecto.UUID.autogenerate()
          :ok = File.write!(filename, binary)
          {:file, filename}

        :from_user_microphone ->
          Nx.from_binary(binary, :f32)
      end

    output = Nx.Serving.batched_run(Ambiantcare.Serving, input)
    transcription = output.chunks |> Enum.map_join(& &1.text) |> String.trim()

    {:ok, transcription}
  end

  defp transcribe_audio(stt_params, upload_metadata) do
    stt_backend = stt_params.stt_backend

    opts =
      stt_params
      |> Map.take([:deployment])
      |> Map.to_list()
      |> Keyword.merge(upload_metadata: upload_metadata)

    with {:ok, filename} <- write_to_file(upload_metadata),
         {:ok, transcription} <-
           apply(stt_backend, :generate, ["openai/whisper-large-v3-turbo", filename, opts]) do
      {:ok, transcription}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp backend_opts(HuggingFace, assigns) do
    [deployment: assigns.huggingface_deployment]
  end

  defp backend_opts(Gladia, _assigns) do
    []
  end

  defp backend_opts(SpeechMatics, _assigns) do
    []
  end

  defp write_to_file(upload_metadata) do
    binary = upload_metadata.binary
    audio_format = audio_format(upload_metadata)
    filename = build_filename(audio_format)

    with :ok <- File.write(filename, binary),
         {:ok, filename} <- maybe_convert_audio(filename, audio_format) do
      {:ok, filename}
    else
      {:error, _} = error -> error
    end
  end

  defp audio_format(upload_metadata) do
    case upload_metadata do
      %{upload_type: :from_user_file_system, client_filename: client_filename} ->
        Path.extname(client_filename)

      _ ->
        ".pcm"
    end
  end

  defp maybe_convert_audio(filename, ".pcm") do
    Audio.pcm_to_flac(filename)
  end

  defp maybe_convert_audio(filename, _) do
    {:ok, filename}
  end

  defp build_filename(:transcription) do
    tmp_dir = System.tmp_dir!()

    datetime =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.to_string()
      |> String.replace(":", "_")
      |> String.replace(" ", "_")

    "#{tmp_dir}/transcription_#{datetime}.txt"
  end

  # @ryanzidago - assuming opus is raw audio without any extensions
  defp build_filename("raw_audio"), do: build_filename("")

  defp build_filename(extension) do
    tmp_dir = System.tmp_dir!()

    datetime =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.to_string()
      |> String.replace(":", "_")
      |> String.replace(" ", "_")

    _filename = "#{tmp_dir}/audio_#{datetime}#{extension}"
  end

  defp maybe_send_to_parent(opts, message) do
    if parent = Keyword.get(opts, :parent), do: send(parent, message)
  end

  defp get_current_transcription(%{} = socket) do
    case Map.get(socket.assigns, :consultation_transcription) do
      %AsyncResult{ok?: true, result: result} when is_binary(result) ->
        result

      _ ->
        ""
    end
  end

  defp query_llm(%{} = params) do
    user_prompt = Prompts.user(params)
    result = Ambiantcare.AI.LLMs.generate("medical_notes/v1_0", user_prompt)

    Logger.debug("*** prompt ***")
    Logger.debug(user_prompt)
    Logger.debug("*** result ***")
    Logger.debug(inspect(result))

    with {:ok, response} <- result,
         {:ok, template} <- Map.fetch(params, :template),
         {:ok, medical_note_changeset} <- response_to_changeset(response, template) do
      {:ok, medical_note_changeset}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp maybe_resume_dedicated_endpoint(%{assigns: %{stt_backend: HuggingFace}} = socket) do
    # @ryanzidago - ensure the endpoint is always running when someone visits the page
    # @ryanzidago - do not hardcode the model name
    with false <- use_local_stt?(),
         {:ok, response} <-
           HuggingFace.Dedicated.Admin.get_endpoint_information("whisper-large-v3-turbo-fkx"),
         state when state != "running" <- get_in(response, ~w(status state)),
         {:ok, _} <- HuggingFace.Dedicated.Admin.resume("whisper-large-v3-turbo-fkx") do
      put_flash(
        socket,
        :warning,
        gettext("Starting the AI server. Please retry in 5 minutes ...")
      )
    else
      _ ->
        socket
    end
  end

  defp log_values(socket) do
    keys = Map.take(socket.assigns, [:stt_backend, :microphone_hook, :huggingface_deployment])
    Logger.info("AmbiantcareWeb.ConsultationsLive mounted with: #{inspect(keys)}")
  end

  defp assign_speech_to_text_backend(socket, %{"stt_backend" => "huggingface"}) do
    assign(socket, stt_backend: HuggingFace)
  end

  defp assign_speech_to_text_backend(socket, %{"stt_backend" => "gladia"}) do
    assign(socket, stt_backend: Gladia)
  end

  defp assign_speech_to_text_backend(socket, %{"stt_backend" => "speechmatics"}) do
    assign(socket, stt_backend: SpeechMatics)
  end

  defp assign_speech_to_text_backend(socket, _params) do
    assign(socket, stt_backend: Gladia)
  end

  defp assign_templates_by_id(socket) do
    templates_by_id =
      [Template.default_template(), Template.gastroenterology_template()]
      |> Map.new(&{&1.key, &1})

    assign(socket, templates_by_id: templates_by_id)
  end

  defp assign_selected_template(socket) do
    selected_template =
      socket.assigns.templates_by_id
      |> Map.values()
      |> List.first()

    assign(socket, selected_template: selected_template)
  end

  defp assign_medical_note_changeset(socket, _params) do
    selected_template = socket.assigns.selected_template

    changeset =
      selected_template
      |> MedicalNote.from_template()
      |> MedicalNote.changeset(%{})

    changeset =
      %AsyncResult{
        ok?: true,
        loading: false,
        result: changeset
      }

    assign(socket, medical_note_changeset: changeset)
  end

  defp response_to_changeset(response, template) do
    template_fields_by_name = Map.new(template.fields, &{&1.name, &1})

    fields =
      response
      |> to_fields()
      |> Enum.map(fn field ->
        template_field = Map.fetch!(template_fields_by_name, field.name)

        field
        |> Map.put(:label, template_field.label)
        |> Map.put(:position, template_field.position)
      end)
      |> Enum.sort_by(& &1.position)

    changeset = MedicalNote.changeset(%MedicalNote{}, %{title: "Some title", fields: fields})

    {:ok, changeset}
  end
end
