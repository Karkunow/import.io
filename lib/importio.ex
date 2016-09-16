defmodule Importio do
  @moduledoc """
    Using example:
      escript importio -rf "C:/flowapps, C:/flow" -f smartbuilder/aacc/aacc_ui_test -oi -sl 20
  """
  import Enum

  @result_filename __DIR__ <> "/diagram/data/force.csv"

  def main(args) do
    parsed = args |> parse_args
    File.rm(@result_filename)
    {:ok, file} = @result_filename |> File.open([:read, :write])
    IO.write(file, "source,target,value\n")
    get_imports(parsed[:file], parsed[:onlyinner], 0, parsed[:depth], file)
    File.close(file)
  end

  defp remove_last(words) do
    slice(words, 0, count(words) - 1)
  end

  defp get_root_folder(filename) do
    String.split(filename, "/")
    |> remove_last
    |> join("/")
  end

  defp transform_options(options) do
    root_folders_raw = options |> Keyword.get(:root_folders)
    root_folders = root_folders_raw |> String.split(", ")
    options |> Keyword.put(:root_folders, root_folders)
  end

  defp parse_args(args) do  
    {options, _, _} = args |> OptionParser.parse(
      switches: [
        root_folders: :string,
        file: :string, 
        onlyinner: :boolean,
        depth: :integer
      ],
      aliases: [
        rf: :root_folders,
        f: :file,
        oi: :onlyinner,
        dp: :depth
      ]
    )
    options |> transform_options
  end

  defp get_imports(filename, only_inner_files, level, depth, results_file) do
    root_folder = get_root_folder(filename)
    if depth > level && searchable?(filename, root_folder, only_inner_files) do
      filenamefull = filename <> ".flow"
      path1 = "C:/flowapps/" <> filenamefull
      path2 = "C:/flow/lib/" <> filenamefull
      path = unless File.exists?(path1), do: path2, else: path1
      
      imported_files = reduce_while(
        File.stream!(path, [], :line),
        [],
        fn line, acc ->
          cond do
            is_import_line?(line) ->
              next_filename = line |> get_filename
              if searchable?(next_filename, root_folder, only_inner_files) do
                result_line = get_result_line(filename, next_filename)
                IO.write(results_file, result_line)
              end
              {:cont, [next_filename | acc]}
            empty?(acc) -> {:cont, acc}
            true -> {:halt, acc}
          end
        end
      )
      
      imported_files
      |> each(
        fn next ->
          get_imports(next, only_inner_files, level + 1, depth, results_file)
        end
      )
    end
  end

  defp get_result_line(filename, next_filename) do
    [filename, next_filename, "0.2\n"] |> join(",")
  end

  defp get_filename(line) do
    "import " <> rest = line
    String.split(rest, ";\n", [trim: true]) |> at(0)
  end

  defp is_import_line?(line) do
    line |> String.starts_with?("import")
  end

  defp searchable?(filename, root_folder, only_inner_files) do
    cond do 
      !only_inner_files -> true
      String.length(root_folder) == 0 -> false
      true -> filename |> String.starts_with?(root_folder)
    end
  end
end
