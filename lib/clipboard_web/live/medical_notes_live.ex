defmodule ClipboardWeb.MedicalNotesLive do
  @doc """
  LiveView managing the medical notes form and visit recording.
  """
  use ClipboardWeb, :live_view

  require Logger

  alias Clipboard.MedicalNotes.MedicalNote
  alias Clipboard.AI.HuggingFace

  alias ClipboardWeb.Microphone

  alias Phoenix.LiveView
  alias Phoenix.LiveView.AsyncResult

  @impl LiveView
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(huggingface_deployment: HuggingFace.deployment(params))
      |> assign(recording?: false)
      |> assign(visit_transcription: nil)
      |> assign(medical_note_changeset: nil)
      |> assign(microphone_hook: Microphone.from_params(params))
      # |> assign(visit_transcription: demo_async_visit_transctiption())
      # |> assign(medical_note_changeset: demo_async_changeset())
      |> allow_upload(:audio, accept: :any, progress: &handle_progress/3, auto_upload: true)

    {:ok, socket}
  end

  @impl LiveView
  def render(assigns) do
    ~H"""
    <div class="lg:h-screen grid lg:grid-cols-8 align-center gap-40 lg:gap-10 lg:p-20 p-10">
      <div class="lg:col-span-2">
        <.sidebar {assigns} />
      </div>
      <div class="lg:col-span-4 lg:overflow-y-auto lg:px-8">
        <.medical_note :if={@medical_note_changeset} medical_note_changeset={@medical_note_changeset} />
      </div>
    </div>
    """
  end

  defp sidebar(assigns) do
    ~H"""
    <div class="flex flex-col gap-10">
      <.recording_button {assigns} />
      <form phx-change="no_op" phx-submit="no_op" class="hidden">
        <.live_file_input upload={@uploads.audio} />
      </form>

      <div class="flex flex-col">
        <.async_result
          :let={visit_transcription}
          :if={@visit_transcription}
          assign={@visit_transcription}
        >
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
    <.button
      type="button"
      id="microphone"
      phx-hook={@microphone_hook}
      phx-click="toggle_recording"
      data-endianness={System.endianness()}
    >
      <%= if not @recording?, do: "Start Visit", else: "End Visit" %>
    </.button>
    """
  end

  defp medical_note(assigns) do
    assigns =
      assign(assigns,
        current_datetime:
          (DateTime.utc_now()
           |> DateTime.truncate(:second)
           |> DateTime.to_string()
           |> String.replace("Z", "")) <> " UTC"
      )

    ~H"""
    <.async_result :let={changeset} :if={@medical_note_changeset} assign={@medical_note_changeset}>
      <:loading>
        <.spinner />
      </:loading>
      <:failed :let={_reason}>
        Oops, something went wrong!
      </:failed>
      <.form
        :let={form}
        for={changeset}
        phx-submit="save-medical-notes"
        class="flex flex-col gap-10 drop-shadow-sm"
      >
        <%= @current_datetime %>
        <.input
          type="textarea"
          field={form[:chief_complaint]}
          label="Chief Complaint"
          input_class="h-80 md:h-28 lg:h-auto"
        />
        <.input
          type="textarea"
          field={form[:history_of_present_illness]}
          label="History of Present Illness"
          input_class="h-80 md:h-28 lg:h-auto"
        />
        <.input
          type="textarea"
          field={form[:assessment]}
          label="Assessment"
          input_class="h-80 md:h-28 lg:h-auto"
        />
        <.input type="textarea" field={form[:plan]} label="Plan" input_class="h-80 md:h-28 lg:h-auto" />
        <.input
          type="textarea"
          field={form[:medications]}
          label="Medications"
          input_class="h-80 md:h-28 lg:h-auto"
        />
        <.input
          type="textarea"
          field={form[:physical_examination]}
          label="Physical Examination"
          input_class="h-80 md:h-28 lg:h-auto"
        />

        <.button type="submit" class="md:w-32">Save</.button>
      </.form>
    </.async_result>
    """
  end

  attr :visit_transcription, :string, required: true

  defp visit_transcription(assigns) do
    ~H"""
    <.form for={%{}} class="drop-shadow-sm" phx-submit="edit_visit_transcription">
      <div class="w-full flex flex-col gap-10">
        <.input
          type="textarea"
          value={@visit_transcription}
          name="visit_transcription"
          label="Visit Transcription"
          input_class="h-[50vh]"
        />
        <.button type="submit" class="md:w-32">Save</.button>
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

  def handle_event("no_op", _params, socket) do
    # We need phx-change and phx-submit on the form for live uploads,
    # but we make predictions immediately using :progress, so we just
    # ignore this event
    {:noreply, socket}
  end

  def handle_event(
        "edit_visit_transcription",
        %{"visit_transcription" => visit_transcription},
        socket
      ) do
    socket =
      assign_async(socket, :visit_transcription, fn ->
        {:ok, medical_note_changeset} = query_llm(visit_transcription)

        {:ok,
         %{
           visit_transcription: visit_transcription,
           medical_note_changeset: medical_note_changeset
         }}
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

    opts = [
      parent: self(),
      huggingface_deployment: socket.assigns.huggingface_deployment,
      microphone_hook: microphone_hook
    ]

    socket =
      assign_async(socket, :visit_transcription, fn ->
        audio_to_structured_text(binary, current_visit_transcription, opts)
      end)

    {:noreply, socket}
  end

  defp handle_progress(:audio, _entry, socket) do
    {:noreply, socket}
  end

  defp audio_to_structured_text(binary, current_visit_transcription, opts) do
    deployment = Keyword.get(opts, :huggingface_deployment)

    with {:ok, filename} <- write_to_file(binary, opts),
         {:ok, transcription} <-
           HuggingFace.generate("openai/whisper-large-v3", filename, deployment: deployment),
         {:ok, medical_note_changeset} <- query_llm(transcription) do
      File.write!(build_filename(:transcription), transcription)
      Logger.debug("*** transcription ***")
      Logger.debug(transcription)
      transcription = current_visit_transcription <> " " <> transcription
      {:ok, %{visit_transcription: transcription, medical_note_changeset: medical_note_changeset}}
    else
      {:error, reason} ->
        maybe_send_to_parent(opts, {:error, reason})
        {:error, reason}
    end
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

  defp query_llm(visit_transcription) do
    prompt = """
    You are a medical assistant that transform unstructured doctor medical notes into structured data.

    Structure the following medical note:
    ```
    #{visit_transcription}
    ```

    Into the following JSON format:
    {
      "chief_complaint": "string",
      "history_of_present_illness": "string",
      "medications": "string",
      "physical_examination": "string",
      "assessment": "string",
      "plan": "string"
    }
    """

    with {:ok, response} <- Clipboard.AI.Mistral.generate("", prompt, []),
         changeset <- MedicalNote.changeset(response) do
      {:ok, changeset}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def demo_async_visit_transctiption do
    %AsyncResult{
      ok?: true,
      loading: false,
      result: demo_visit_transcription()
    }
  end

  def demo_async_changeset do
    %AsyncResult{
      ok?: true,
      loading: false,
      result: MedicalNote.changeset(%{})
    }
  end

  defp demo_visit_transcription do
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
end
