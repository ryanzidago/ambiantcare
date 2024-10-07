defmodule Ambiantcare.MedicalNotes.FieldNames do
  @names [
    :chief_complaint,
    :present_medical_history,
    :assessment,
    :past_medical_history,
    :ongoing_therapy,
    :therapeutic_plan,
    :medications,
    :physical_assessment,
    :home_medications,
    :allergies,
    :physical_examination,
    :conclusions,
    :therapeutic_advices
  ]

  def names, do: @names
end
