defmodule FileTools do

  def remove_lines(filename, lines) do
    temporary_name = "importio_test_name_file"
    File.rename(filename, temporary_name)
    
    File.stream!(temporary_name)
    |> Stream.with_index
    |> Stream.filter(fn {_textline, i} -> !Enum.member?(lines, i) end)
    |> Stream.map(fn item -> item |> elem(0) end)
    |> Stream.into(File.stream!(filename))
    |> Stream.run

    File.rm(temporary_name)
  end

end