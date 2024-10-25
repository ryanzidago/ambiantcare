defmodule AmbiantcareWeb.MedicalNotesLive do
  @doc """
  LiveView managing the medical notes form and visit recording.
  """
  use AmbiantcareWeb, :live_view

  use Gettext, backend: AmbiantcareWeb.Gettext

  require Logger

  import Ecto.Changeset
  import AmbiantcareWeb.MedicalNotesLive.Helpers

  alias Phoenix.LiveView
  alias Phoenix.LiveView.AsyncResult
  alias Phoenix.LiveView.UploadEntry
  alias Ecto.Changeset

  alias Ambiantcare.MedicalNotes.Template
  alias Ambiantcare.MedicalNotes.MedicalNote
  alias Ambiantcare.MedicalNotes.Prompts
  alias Ambiantcare.Audio

  alias Ambiantcare.AI.HuggingFace
  alias Ambiantcare.AI.Gladia
  alias Ambiantcare.AI.SpeechMatics

  alias AmbiantcareWeb.Microphone
  alias AmbiantcareWeb.Hooks.SetLocale

  @impl LiveView
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_speech_to_text_backend(params)
      |> assign_huggingface_deployment(params)
      |> assign_templates_by_id()
      |> assign_selected_template()
      |> assign(recording?: false)
      |> assign(visit_transcription: %AsyncResult{ok?: true, loading: false, result: nil})
      |> assign(visit_transcription_loading: false)
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
    <div class="grid lg:grid-cols-2 align-center gap-40 lg:gap-10 lg:p-20 p-10">
      <div class="lg:col-span-1">
        <.action_panel
          current_action={@current_action}
          visit_transcription={@visit_transcription}
          visit_transcription_loading={@visit_transcription_loading}
          visit_context={@visit_context}
          medical_note_loading={@medical_note_loading}
          uploads={@uploads}
          upload_type={@upload_type}
          microphone_hook={@microphone_hook}
          recording?={@recording?}
          selected_pre_recorded_audio_file={@selected_pre_recorded_audio_file}
        />
      </div>
      <div class="lg:col-span-1 lg:overflow-y-auto lg:px-8">
        <.medical_note
          medical_note_changeset={@medical_note_changeset}
          selected_template={@selected_template}
        />
      </div>
    </div>
    """
  end

  defp action_panel(assigns) do
    ~H"""
    <div class="flex flex-col gap-10">
      <div class="inline-flex" role="group">
        <.button
          type="button"
          phx-click="toggle_action_panel"
          phx-value-action="transcription"
          class="rounded-none rounded-l-lg"
        >
          <%= gettext("Transcription") %>
        </.button>
        <.button
          type="button"
          phx-click="toggle_action_panel"
          phx-value-action="visit_context"
          class="rounded-none rounded-r-lg"
        >
          <%= gettext("Context") %>
        </.button>
      </div>
      <%= case @current_action do %>
        <% "transcription" -> %>
          <.transcription_panel
            visit_transcription={@visit_transcription}
            visit_transcription_loading={@visit_transcription_loading}
            medical_note_loading={@medical_note_loading}
            uploads={@uploads}
            upload_type={@upload_type}
            microphone_hook={@microphone_hook}
            recording?={@recording?}
            selected_pre_recorded_audio_file={@selected_pre_recorded_audio_file}
          />
        <% "visit_context" -> %>
          <.consultation_panel visit_context={@visit_context} />
      <% end %>
    </div>
    """
  end

  defp transcription_panel(assigns) do
    ~H"""
    <div class="flex flex-col gap-10">
      <.recording_button
        recording?={@recording?}
        microphone_hook={@microphone_hook}
        visit_transcription_loading={@visit_transcription_loading}
        uploads={@uploads}
        upload_type={@upload_type}
        selected_pre_recorded_audio_file={@selected_pre_recorded_audio_file}
      />

      <div class="flex flex-col">
        <.async_result :let={visit_transcription} assign={@visit_transcription}>
          <:failed :let={_reason}>
            <span class="flex flex-col items-center">Oops, something went wrong!</span>
          </:failed>
          <.visit_transcription
            visit_transcription={visit_transcription}
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

  attr :recording?, :boolean, required: true
  attr :microphone_hook, :string, required: true
  attr :visit_transcription_loading, :boolean, required: true
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
            <%= gettext("Start Visit") %>
          </span>

          <span :if={@recording?}>
            <%= gettext("End Visit") %>
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
        :if={@visit_transcription_loading}
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

  attr :visit_transcription, :string, required: true
  attr :medical_note_loading, :boolean, required: true

  defp visit_transcription(assigns) do
    ~H"""
    <.form
      for={%{}}
      class="drop-shadow-sm text-sm"
      phx-change="change_visit_transcription"
      phx-submit="generate_medical_note"
    >
      <div class="w-full flex flex-col gap-10">
        <.input
          type="textarea"
          value={@visit_transcription}
          name="visit_transcription"
          label={gettext("Visit Transcription")}
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
                  data: @visit_transcription,
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
                  text: @visit_transcription
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
    socket = SetLocale.set(socket, locale, "/medical-notes")
    {:noreply, socket}
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
        "change_visit_transcription",
        %{"visit_transcription" => visit_transcription},
        socket
      ) do
    visit_transcription = %AsyncResult{ok?: true, loading: false, result: visit_transcription}
    socket = assign(socket, visit_transcription: visit_transcription)
    {:noreply, socket}
  end

  def handle_event(
        "generate_medical_note",
        %{"visit_transcription" => visit_transcription},
        socket
      ) do
    selected_template = socket.assigns.selected_template
    context = socket.assigns.visit_context.result
    params = %{context: context, transcription: visit_transcription, template: selected_template}

    socket =
      socket
      |> assign(medical_note_loading: true)
      |> start_async(:generate_medical_note, fn -> query_llm(params) end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:error, reason}, socket) do
    Logger.error(reason)
    {:noreply, socket}
  end

  @impl true
  def handle_async(:audio_to_structured_text, {:ok, {:ok, result}}, socket) do
    visit_transcription = AsyncResult.ok(result.visit_transcription)
    medical_note_changeset = AsyncResult.ok(result.medical_note_changeset)

    socket =
      socket
      |> assign(visit_transcription_loading: false)
      |> assign(visit_transcription: visit_transcription)
      |> assign(medical_note_changeset: medical_note_changeset)

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
    current_visit_transcription = get_current_transcription(socket)
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
      |> Map.put(:transcription, current_visit_transcription)
      |> Map.put(:template, selected_template)
      |> Map.put(:visit_context, context)
      |> Map.put(:locale, Gettext.get_locale(AmbiantcareWeb.Gettext))

    opts = [parent: self()]

    socket =
      socket
      |> assign(visit_transcription_loading: true)
      |> start_async(:audio_to_structured_text, fn ->
        audio_to_structured_text(stt_params, upload_metadata, context_params, opts)
      end)

    {:noreply, socket}
  end

  defp process_audio(_key, _entry, socket) do
    {:noreply, socket}
  end

  defp assign_huggingface_deployment(socket, params) do
    if socket.assigns.stt_backend == HuggingFace do
      assign(socket, huggingface_deployment: HuggingFace.deployment(params))
    else
      socket
    end
  end

  defp audio_to_structured_text(stt_params, upload_metadata, context_params, opts) do
    current_visit_transcription = context_params.transcription

    with {:ok, transcription} <- transcribe_audio(stt_params, upload_metadata),
         {:ok, medical_note_changeset} <- query_llm(context_params) do
      Logger.debug("*** begin transcription ***")
      Logger.debug(transcription)
      Logger.debug("*** end transcription ***")

      transcription = current_visit_transcription <> " " <> transcription

      {:ok, %{visit_transcription: transcription, medical_note_changeset: medical_note_changeset}}
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
    case Map.get(socket.assigns, :visit_transcription) do
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
         {:ok, response} =
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
    Logger.info("AmbiantcareWeb.MedicalNotesLive mounted with: #{inspect(keys)}")
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
