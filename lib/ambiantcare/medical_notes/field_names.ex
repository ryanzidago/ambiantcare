defmodule Ambiantcare.MedicalNotes.FieldNames do
  @names [
    :chief_complaint,
    :history_of_present_illness,
    :assessment,
    :plan,
    :medications,
    :past_medical_history,
    :home_medications,
    :allergies,
    :physical_examination,
    :conclusions,
    :therapeutic_advices
  ]

  def names, do: @names
end
