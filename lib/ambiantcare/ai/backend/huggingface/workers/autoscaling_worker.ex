defmodule Ambiantcare.AI.HuggingFace.AutoScalingWorker do
  @moduledoc """
  Worker for autoscaling dedicated Hugging Face endpoints.
  """
  use Oban.Worker, queue: :default

  alias Ambiantcare.AI.HuggingFace.Admin

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"action" => "resume"}}) do
    Admin.resume("whisper-large-v3-turbo-fkx")
  end

  def perform(%Oban.Job{args: %{"action" => "scale_to_zero"}}) do
    Admin.scale_to_zero("whisper-large-v3-turbo-fkx")
  end
end
