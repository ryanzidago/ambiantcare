defmodule Clipboard.Audio do
  def convert(filename, opts \\ []) do
    [filename_without_extension, _extension] = String.split(filename, ".")

    input_format = Keyword.get(opts, :input_format, "f32le")
    target_extension = Keyword.get(opts, :target_extension, "flac")
    sample_rate = Keyword.get(opts, :sample_rate, "16000")
    channels = Keyword.get(opts, :channels, "1")
    codec = Keyword.get(opts, :codec, "flac")

    result =
      System.cmd(
        "ffmpeg",
        ~w(
          -f #{input_format}
          -ar #{sample_rate}
          -ac #{channels}
          -i #{filename}
          -codec:a #{codec}
          -y
          #{filename_without_extension}.#{target_extension})
      )

    case result do
      {_output, 0} -> {:ok, "#{filename_without_extension}.#{target_extension}"}
      {output, _} -> {:error, output}
    end
  end
end
