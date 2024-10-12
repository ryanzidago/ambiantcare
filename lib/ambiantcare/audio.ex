defmodule Ambiantcare.Audio do
  @sample_rate 16_000

  @doc """
  Converts raw audio to flac format.
  """
  def raw_to_flac(input_filename) when is_binary(input_filename) do
    output_filename = input_filename <> ".flac"

    args = [
      "-i",
      input_filename,
      "-c:a",
      "flac",
      "-ar",
      Integer.to_string(@sample_rate),
      "-ac",
      "1",
      "-y",
      "#{output_filename}"
    ]

    execute(args, output_filename)
  end

  def pcm_to_flac(input_filename, opts \\ []) do
    [filename_without_extension, _extension] = String.split(input_filename, ".")

    input_format = Keyword.get(opts, :input_format, "f32le")
    target_extension = Keyword.get(opts, :target_extension, "flac")
    sample_rate = Keyword.get(opts, :sample_rate, "16000")
    channels = Keyword.get(opts, :channels, "1")
    codec = Keyword.get(opts, :codec, "flac")
    output_filename = "#{filename_without_extension}.#{target_extension}"

    args = ~w(
          -f #{input_format}
          -ar #{sample_rate}
          -ac #{channels}
          -i #{input_filename}
          -codec:a #{codec}
          -y
          #{output_filename}
        )

    execute(args, output_filename)
  end

  defp execute(args, output_filename) do
    IO.puts("\n")

    case System.cmd("ffmpeg", args) do
      {_output, 0} ->
        IO.puts("\n")
        {:ok, output_filename}

      {output, error_code} ->
        IO.puts("\n")
        {:error, %{output: output, error_code: error_code}}
    end
  end
end
