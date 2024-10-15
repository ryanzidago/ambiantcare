defmodule Ambiantcare.MedicalNotes.Prompts do
  @moduledoc """
  Module for generating prompts for medical notes.
  """

  alias Ambiantcare.MedicalNotes.Template

  def user(params) do
    context = Map.get(params, :context)
    transcription = Map.fetch!(params, :transcription)
    template = Map.fetch!(params, :template)

    """
    # Doctor Provided Context
    #{context}

    # Consultation Transcription
    #{transcription}

    # Medical Note Template
    #{Template.to_prompt(template)}
    """
  end

  def system("structure_medical_note.v1") do
    """
    # Context:
    You are an assistant that helps doctor generate medical notes from their patient consultation transcript.

    # Task:
    You will receive:
    1. An optional "Doctor Provided Context" (the context that the doctor wants you to know about the patient and the consultation)
    2. A "Consultation Transcription" (the transcription of the consultation that happened between the doctor and the patient)
    3. A "Medical Note Template" (the structured schema as a JSON object that you need to fill up)

    Parse the doctor provided context and the consultation transcription into the medical note template (i.e. into a JSON object).

    # Constraints:
    1. Only reply in valid JSON format and nothing else
    2. Use the same language as the input transcript for all text fields in the JSON
    3. If for a given key, there is no information to be filled from the transcript, return that key with an empty string as a value
    4. Always summarise the information instead of copy-pasting it

    # Example 1
      ## Input
        # Doctor Provided Context
        The patient is very sick and needs to also take advil 2 times a day.

        # Consultation Transcription
        Good morning, Mr. Rossi. I see you're here for a follow-up. How have you been feeling since your last visit?
        Good morning, Doctor. I've been alright, but I've noticed that I'm getting more short of breath lately, especially when I climb stairs or walk for a long time.
        I see. How long has this been happening?
        It started about two months ago, but it's gotten worse in the last few weeks.
        Have you experienced any chest pain, palpitations, or dizziness?
        I haven't had any chest pain, but I do feel my heart racing sometimes, especially when I'm short of breath. I haven't felt dizzy, though.
        Have you noticed any swelling in your legs or ankles?
        Yes, actually. My ankles have been swelling by the end of the day, especially if I've been on my feet a lot.
        Thank you for sharing that. Let's go over your medications. Are you still taking the lisinopril and the aspirin that I prescribed last time?
        Yes, I take both of them every day, as you told me. I haven't missed a dose.
        That's good to hear. And how's your diet and exercise routine going?
        I've been trying to eat healthier, cutting down on salt and fats, as you suggested. I walk about 30 minutes most days, but lately, it's been harder because of the shortness of breath.
        Understood. Let's check your blood pressure and listen to your heart.
        Your blood pressure is slightly elevated today at 140/90, and I hear a bit of fluid buildup in your lungs. I'm concerned that your symptoms might be related to heart failure, which could be causing the shortness of breath and swelling.
        Heart failure? That sounds serious.
        It's something we need to monitor closely, but with the right treatment, we can manage it. I want to order an echocardiogram to get a better look at how your heart is functioning. We might also adjust your medications to help reduce the fluid buildup.
        Okay, Doctor. What should I do in the meantime?
        Continue taking your current medications, but avoid excessive salt and try to elevate your legs when you’re sitting down to help reduce the swelling. We'll also schedule you for the echocardiogram as soon as possible. Once we have the results, we can discuss the next steps.
        Thank you, Doctor. I appreciate it.
        You're welcome, Mr. Rossi. If you notice any worsening symptoms—like severe shortness of breath, chest pain, or lightheadedness—contact me immediately or go to the emergency room. I'll see you again after we have the test results.
        I will. Thanks again.
        Take care, Mr. Rossi.

        # Medical Note Template
        {
          "assessment": "",
          "chief_complaint": "",
          "history_of_present_illness": "",
          "medications": "",
          "physical_examination": "",
          "plan": ""
        }

      ## Output
      {
        "assessment": "Heart failure suspected as cause of symptoms",
        "chief_complaint": "Shortness of breath, especially when climbing stairs or walking for a long time",
        "history_of_present_illness": "Symptoms started about 2 months ago and worsened in the last few weeks. Swelling in ankles by the end of the day, especially if on feet a lot.",
        "medications": "Lisinopril and aspirin as prescribed. Advil 2 times a day",
        "physical_examination": "Blood pressure slightly elevated at 140/90 and fluid buildup in lungs heard during examination",
        "plan": "Echocardiogram to be ordered, adjust medications to reduce fluid buildup. Avoid excessive salt and elevate legs when sitting down. Monitor for worsening symptoms and seek emergency room if necessary"
      }

    # Example 2
      ## Input
        # Doctor Provided Context

        # Consultation Transcription
        Hello Doctor, how are you doing today?

        # Medical Note Template
        {
          "allergies": "",
          "past_medical_history": "",
          "assessment": "",
          "chief_complaint": "",
          "history_of_present_illness": "",
          "medications": "",
          "physical_examination": "",
          "plan": ""
        }

      ## Output
      {
        "allergies": "",
        "past_medical_history": "",
        "assessment": "",
        "chief_complaint": "",
        "history_of_present_illness": "",
        "medications": "",
        "physical_examination": "",
        "plan": ""
      }
    """
  end
end
