defmodule ClipboardWeb.MedicalNotesLive do
  @doc """
  LiveView managing the medical notes form and visit recording.
  """
  use ClipboardWeb, :live_view

  use Gettext, backend: ClipboardWeb.Gettext

  require Logger

  import Ecto.Changeset
  import ClipboardWeb.MedicalNotesLive.Helpers

  alias Phoenix.LiveView
  alias Phoenix.LiveView.AsyncResult

  alias Clipboard.MedicalNotes.Template
  alias Clipboard.MedicalNotes.MedicalNote
  alias Clipboard.MedicalNotes.Prompts

  alias Clipboard.AI.HuggingFace
  alias Clipboard.AI.Gladia
  alias Clipboard.AI.SpeechMatics

  alias ClipboardWeb.Microphone
  alias ClipboardWeb.SetLocale

  @impl LiveView
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_speech_to_text_backend(params)
      |> assign_huggingface_deployment(params)
      |> assign_templates_by_id()
      |> assign_selected_template()
      |> assign(recording?: false)
      |> assign(visit_transcription: nil)
      |> assign(medical_note_changeset: nil)
      |> assign(microphone_hook: Microphone.from_params(params))
      |> assign(visit_transcription: maybe_demo_visit_transcription(params))
      |> assign_medical_note_changeset(params)
      |> assign(url_params: params)
      |> allow_upload(:audio, accept: :any, progress: &handle_progress/3, auto_upload: true)

    maybe_resume_dedicated_endpoint(socket)
    log_values(socket)

    {:ok, socket}
  end

  @impl LiveView
  def render(assigns) do
    ~H"""
    <div class="grid lg:grid-cols-2 align-center gap-40 lg:gap-10 lg:p-20 p-10">
      <div class="lg:col-span-1">
        <.transcription_panel {assigns} />
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

  defp transcription_panel(assigns) do
    ~H"""
    <div class="flex flex-col gap-10">
      <.recording_button {assigns} />
      <form phx-change="no_op" phx-submit="no_op" class="hidden">
        <.live_file_input upload={@uploads.audio} />
      </form>

      <div class="flex flex-col">
        <.async_result :let={visit_transcription} assign={@visit_transcription}>
          <:loading>
            <div class="flex flex-col items-center">
              <.spinner />
            </div>
          </:loading>
          <:failed :let={_reason}>
            <span class="flex flex-col items-center">Oops, something went wrong!</span>
          </:failed>
          <quote class="text-sm">
            <.visit_transcription visit_transcription={visit_transcription} />
          </quote>
        </.async_result>
      </div>
    </div>
    """
  end

  attr :recording?, :boolean, required: true
  attr :microphone_hook, :string, required: true

  defp recording_button(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-between">
      <.button
        type="button"
        id="microphone"
        phx-hook={@microphone_hook}
        phx-click="toggle_recording"
        data-endianness={System.endianness()}
        class="md:w-32"
      >
        <%= if not @recording?, do: gettext("Start Visit"), else: gettext("End Visit") %>
      </.button>

      <div :if={@recording?} class="flex flex-row items-center justify-center gap-4">
        <div class="w-3 h-3 rounded-full bg-red-600 animate-pulse"></div>
        Recording
      </div>
    </div>
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
      <:loading>
        <.spinner />
      </:loading>
      <:failed :let={_reason}>
        Oops, something went wrong!
      </:failed>
      <.form :let={form} for={changeset} class="flex flex-col gap-10 drop-shadow-sm">
        <.inputs_for :let={field} field={form[:fields]}>
          <.field field={field} selected_template={@selected_template} />
        </.inputs_for>

        <div class="flex flex-row gap-10">
          <.button type="button" class="md:w-32"><%= gettext("Save") %></.button>
          <.button
            type="button"
            class="md:w-32"
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
            class="md:w-32"
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
      |> assign(label: Gettext.gettext(ClipboardWeb.Gettext, template_field.label))
      |> assign(value: value)

    ~H"""
    <.input type={@input_type} name={@name} label={@label} value={@value} />
    """
  end

  attr :visit_transcription, :string, required: true

  defp visit_transcription(assigns) do
    ~H"""
    <.form
      for={%{}}
      class="drop-shadow-sm"
      phx-change="change_visit_transcription"
      phx-submit="submit_visit_transcription"
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
          <.button type="submit" class="md:w-32"><%= gettext("Save") %></.button>
          <.button
            type="button"
            class="md:w-32"
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
            class="md:w-32"
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
  def handle_event("toggle_recording", _params, socket) when not socket.assigns.recording? do
    socket = assign(socket, recording?: true)
    {:noreply, socket}
  end

  def handle_event("toggle_recording", _params, socket) when socket.assigns.recording? do
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

  def handle_event("no_op", _params, socket) do
    # We need phx-change and phx-submit on the form for live uploads,
    # but we make predictions immediately using :progress, so we just
    # ignore this event
    {:noreply, socket}
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
        "submit_visit_transcription",
        %{"visit_transcription" => visit_transcription},
        socket
      ) do
    selected_template = socket.assigns.selected_template

    socket =
      assign_async(socket, :visit_transcription, fn ->
        case query_llm(visit_transcription, selected_template) do
          {:ok, medical_note_changeset} ->
            {:ok,
             %{
               visit_transcription: visit_transcription,
               medical_note_changeset: medical_note_changeset
             }}

          {:error, reason} ->
            {:error, reason}
        end
      end)

    {:noreply, socket}
  end

  @impl LiveView
  def handle_info({:error, reason}, socket) do
    Logger.error(reason)
    {:noreply, socket}
  end

  defp handle_progress(:audio, entry, socket) when entry.done? do
    microphone_hook = Map.fetch!(socket.assigns, :microphone_hook)
    binary = consume_uploaded_entry(socket, entry, fn %{path: path} -> File.read(path) end)
    current_visit_transcription = get_current_transcription(socket)
    stt_backend = socket.assigns.stt_backend
    selected_template = socket.assigns.selected_template

    params =
      %{}
      |> Map.put(:stt_backend, stt_backend)
      |> Map.put(:binary, binary)
      |> Map.put(:current_visit_transcription, current_visit_transcription)
      |> Map.put(:selected_template, selected_template)

    opts =
      []
      |> Keyword.put(:parent, self())
      |> Keyword.put(:microphone_hook, microphone_hook)
      |> Keyword.put(:locale, Gettext.get_locale(ClipboardWeb.Gettext))
      |> Keyword.merge(backend_opts(stt_backend, socket.assigns))

    socket =
      assign_async(socket, :visit_transcription, fn -> audio_to_structured_text(params, opts) end)

    {:noreply, socket}
  end

  defp handle_progress(:audio, _entry, socket) do
    {:noreply, socket}
  end

  defp assign_huggingface_deployment(socket, params) do
    if socket.assigns.stt_backend == HuggingFace do
      assign(socket, huggingface_deployment: HuggingFace.deployment(params))
    else
      socket
    end
  end

  defp audio_to_structured_text(
         %{
           stt_backend: stt_backend,
           binary: binary,
           current_visit_transcription: current_visit_transcription,
           selected_template: selected_template
         },
         opts
       ) do
    with {:ok, filename} <- write_to_file(binary, opts),
         {:ok, transcription} <- transcribe_audio(stt_backend, filename, opts),
         {:ok, medical_note_changeset} <- query_llm(transcription, selected_template) do
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

  defp transcribe_audio(stt, filename, opts) do
    apply(stt, :generate, ["openai/whisper-large-v3", filename, opts])
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

  defp write_to_file(binary, opts) do
    audio =
      case Keyword.fetch!(opts, :microphone_hook) do
        "Microphone" -> :opus
        "StreamMicrophone" -> :raw_audio
      end

    filename = build_filename(audio)

    audio_convert_fn =
      case audio do
        :opus -> fn filename -> Clipboard.Audio.opus_to_flac(filename) end
        :raw_audio -> fn filename -> Clipboard.Audio.raw_to_flac(filename) end
      end

    with :ok <- File.write(filename, binary),
         {:ok, filename} <- audio_convert_fn.(filename) do
      {:ok, filename}
    else
      {:error, _} = error -> error
    end
  end

  defp build_filename(:raw_audio) do
    tmp_dir = System.tmp_dir!()

    datetime =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.to_string()
      |> String.replace(":", "_")
      |> String.replace(" ", "_")

    _filename = "#{tmp_dir}/audio_#{datetime}"
  end

  defp build_filename(:opus) do
    tmp_dir = System.tmp_dir!()

    datetime =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.to_string()
      |> String.replace(":", "_")
      |> String.replace(" ", "_")

    _filename = "#{tmp_dir}/audio_#{datetime}.opus"
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

  defp query_llm(visit_transcription, selected_template) do
    prompt = Prompts.transcription_to_medical_note(visit_transcription, selected_template)
    result = Clipboard.AI.Mistral.generate("", prompt, [])

    Logger.debug("*** prompt ***")
    Logger.debug(prompt)
    Logger.debug("*** result ***")
    Logger.debug(inspect(result))

    with {:ok, response} <- result,
         {:ok, medical_note_changeset} <- response_to_changeset(response, selected_template) do
      {:ok, medical_note_changeset}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp maybe_resume_dedicated_endpoint(socket) do
    if socket.assigns.stt_backend == HuggingFace and is_nil(socket.assigns.visit_transcription) do
      Logger.debug("Resuming HuggingFace endpoint")
      # @ryanzidago - ensure the endpoint is always running when someone visits the page
      _ = HuggingFace.Dedicated.Admin.resume("whisper-large-v3-yse")
    else
      {:ok, :no_op}
    end
  end

  defp maybe_demo_visit_transcription(params) do
    locale = Gettext.get_locale(ClipboardWeb.Gettext)

    case Map.get(params, "use_demo_transcription") do
      "true" -> demo_async_visit_transctiption(locale)
      _ -> %AsyncResult{ok?: true, loading: false, result: nil}
    end
  end

  defp log_values(socket) do
    keys = Map.take(socket.assigns, [:stt_backend, :microphone_hook, :huggingface_deployment])
    Logger.info("ClipboardWeb.MedicalNotesLive mounted with: #{inspect(keys)}")
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

  def demo_async_visit_transctiption(locale \\ :en) do
    %AsyncResult{
      ok?: true,
      loading: false,
      result: demo_visit_transcription(locale)
    }
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

  defp demo_visit_transcription(locale)

  defp demo_visit_transcription("en") do
    """
    Cardiologist: Good morning, Mr. Rossi. I see you're here for a follow-up. How have you been feeling since your last visit?

    Patient (Mr. Rossi): Good morning, Doctor. I've been alright, but I've noticed that I'm getting more short of breath lately, especially when I climb stairs or walk for a long time.

    Cardiologist: I see. How long has this been happening?

    Patient: It started about two months ago, but it's gotten worse in the last few weeks.

    Cardiologist: Have you experienced any chest pain, palpitations, or dizziness?

    Patient: I haven't had any chest pain, but I do feel my heart racing sometimes, especially when I'm short of breath. I haven't felt dizzy, though.

    Cardiologist: Have you noticed any swelling in your legs or ankles?

    Patient: Yes, actually. My ankles have been swelling by the end of the day, especially if I've been on my feet a lot.

    Cardiologist: Thank you for sharing that. Let's go over your medications. Are you still taking the lisinopril and the aspirin that I prescribed last time?

    Patient: Yes, I take both of them every day, as you told me. I haven't missed a dose.

    Cardiologist: That's good to hear. And how's your diet and exercise routine going?

    Patient: I've been trying to eat healthier, cutting down on salt and fats, as you suggested. I walk about 30 minutes most days, but lately, it's been harder because of the shortness of breath.

    Cardiologist: Understood. Let's check your blood pressure and listen to your heart.

    [The cardiologist performs a physical examination.]

    Cardiologist: Your blood pressure is slightly elevated today at 140/90, and I hear a bit of fluid buildup in your lungs. I'm concerned that your symptoms might be related to heart failure, which could be causing the shortness of breath and swelling.

    Patient: Heart failure? That sounds serious.

    Cardiologist: It's something we need to monitor closely, but with the right treatment, we can manage it. I want to order an echocardiogram to get a better look at how your heart is functioning. We might also adjust your medications to help reduce the fluid buildup.

    Patient: Okay, Doctor. What should I do in the meantime?

    Cardiologist: Continue taking your current medications, but avoid excessive salt and try to elevate your legs when you’re sitting down to help reduce the swelling. We'll also schedule you for the echocardiogram as soon as possible. Once we have the results, we can discuss the next steps.

    Patient: Thank you, Doctor. I appreciate it.

    Cardiologist: You're welcome, Mr. Rossi. If you notice any worsening symptoms—like severe shortness of breath, chest pain, or lightheadedness—contact me immediately or go to the emergency room. I'll see you again after we have the test results.

    Patient: I will. Thanks again.

    Cardiologist: Take care, Mr. Rossi.
    """
  end

  defp demo_visit_transcription("it") do
    """
     Come si sente oggi?

     Non tanto bene, dottore.
     Ho avuto un forte mal di testa per tre giorni consecutivi e ultimamente mi sento molto stanco.

     Capisco. Ha notato altri sintomi? Febbre, nausea o problemi di vista?

     No, niente febbre o nausea, ma a volte vedo delle macchie scure davanti agli occhi, soprattutto quando mi alzo rapidamente.

     Ha cambiato qualcosa nella sua routine, come dieta o orari di sonno?

     In effetti, ho dormito meno del solito e ho mangiato più cibo da asporto nelle ultime settimane a causa del lavoro.

     Potrebbe influire, ma vorrei comunque fare qualche controllo. La pressione sanguigna sembra un po' alta. Ha una storia familiare di ipertensione?

     Sì, mio padre soffre di ipertensione da anni. Va bene, faremo qualche esame del sangue per escludere eventuali altre cause.

     Intanto le consiglio di riposare di più e cercare di seguire una dieta più equilibrata.
    """
  end
end
