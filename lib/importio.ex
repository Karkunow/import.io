defmodule Importio do
  @moduledoc """
    Using example:
      escript importio -rf "C:/flowapps, C:/flow" -f smartbuilder/aacc/aacc_ui_test -oi -sl 20
  """
  import Enum

  @result_filename __DIR__ <> "/diagram/data/force.csv"

  def main(args) do
    parsed = args |> parse_args
    IO.inspect Poison.encode(%{a: 1, b: ["aa", "a", 1]})
    IO.inspect parsed
    File.rm(@result_filename)
    {:ok, file} = @result_filename |> File.open([:read, :write])
    IO.write(file, "source,target,value\n")
    root_filename = parsed[:file]
    root_folder = get_root_folder(root_filename)
    # Those are constants while we iterating through files
    options = %ImportOptions{
      file: file,
      root_folder: root_folder,
      folders: parsed[:root_folders],
      onlyinner: parsed[:onlyinner],
      treeform: parsed[:tree],
      max_depth: parsed[:depth]
    }
    get_imports(root_filename, 0, options)
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
        tree: :boolean,
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

  defp get_imports(filename, level, options) do
    # Extracting options
    depth = options.max_depth
    only_inner_files = options.onlyinner
    results_file = options.file
    root_folder = options.root_folder
    folders = options.folders

    if depth > level && searchable?(filename, root_folder, only_inner_files) do
      
      path = 
        get_file_path(filename, folders)

      imported_files = 
        get_imported_files(path, filename, root_folder, only_inner_files, results_file)
      
      imported_files
      |> each(
        fn next_file ->
          get_imports(next_file, level + 1, options)
        end
      )
    end
  end

  defp get_file_path(filename, root_folders) do
     raw_result = reduce_while(root_folders, {:error, ""},
        fn root_folder, acc ->
          path = root_folder <> "/" <> filename <> ".flow"
          if File.exists?(path) do
            {:halt, {:ok, path}}
          else
            {:cont, acc}
          end
        end
      )

    case raw_result do
      {:ok, path} -> path
      {:error, _} -> 
        IO.puts "Can't find file " <> filename <> " anywhere in folders you mentioned. Please, add more root folders."
        System.halt(0)
    end
  end

  defp get_imported_files(path, filename, root_folder, only_inner_files, results_file) do
    reduce_while(
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
  end

  defp get_result_line(filename, next_filename) do
    [filename, next_filename, "0.2\n"] |> join(",")
  end

  defp get_filename(line) do
    "import " <> rest = line
    String.split(rest, ";", [trim: true]) |> at(0)
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