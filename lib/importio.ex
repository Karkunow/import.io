defmodule Importio do
  @moduledoc """
    Using example:
      escript importio --rootfolders="C:/flowapps, C:/flow" --file=smartbuilder/aacc/aacc_ui_test.flow
  """
  def main(args) do
    parsed = args |> parse_args
    #IO.inspect parsed
    {{y, m, d}, {hh, mm, ss}} = :calendar.local_time()
    ints = [y, m, d, hh, mm, ss];
    timestamp = ints |> Enum.join("-");
    {:ok, file} = File.open(get_fname(""), [:read, :write])
    IO.write(file, "source,target,value\n")
    rootf = get_root_folder(parsed[:file])
    IO.puts rootf
    IO.inspect get_imports(parsed[:file], file, 0, 20, parsed[:onlyinner], rootf)
    File.close(file)
  end

  defp get_root_folder(filename) do
    chunks = String.split(filename, "/")
    chunks |> Enum.slice(0, Enum.count(chunks)-1) |> Enum.join("/")
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [rootfolders: :string, file: :string, onlyinner: :boolean],
      aliases: [rf: :root_folders, f: :file, oi: :onlyinner]
    )
    root_folders_raw = options |> Keyword.get(:root_folders)
    root_folders = root_folders_raw |> String.split(", ")
    options |> Keyword.put(:root_folders, root_folders)
  end

  defp get_fname(timestamp) do
    __DIR__ <> "/" <> timestamp <>"force.csv"
  end

  defp get_imports(filename, result_file, level, stop_level, oinner, root_folder) do
    if stop_level > level && searchable?(filename, root_folder, oinner) do
      filenamefull = filename <> ".flow"
      path1 = "C:/flowapps/" <> filenamefull
      path2 = "C:/flow/lib/" <> filenamefull
      path = unless File.exists?(path1), do: path2, else: path1

      filelabel = "[----" <> filename <> "----]"
      #IO.puts filelabel <> "\n"
      is_import_line? = fn(line) ->
        line |> String.starts_with?("import")
      end
      
      Enum.reduce_while(
        File.stream!(path, [], :line),
        :ok,
        fn line, acc ->
          if is_import_line?.(line) do
            "import " <> rest = line
            next_filename = String.split(rest, ";\n", [trim: true]) |> Enum.at(0)
            #IO.puts "\t" <> next_filename
            result_line = [filename, next_filename, "0.2\n"] |> Enum.join(",")
            if searchable?(next_filename, root_folder, oinner), do: IO.write(result_file, result_line)
            get_imports(next_filename, result_file, level + 1, stop_level, oinner, root_folder)
            {:cont, :ok}
          else
            {:halt, acc}
          end
        end
      )
      #IO.puts "\n" <> filelabel <> "\n"  
    end
  end

  defp searchable?(filename, root_folder, oinner) do
    unless oinner do
      true
    else
      filename |> String.starts_with?(root_folder)
    end
  end
end
