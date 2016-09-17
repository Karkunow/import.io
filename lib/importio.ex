defmodule Importio do
  @moduledoc """
    Using example:
      escript importio -rf "C:/flowapps, C:/flow" -f smartbuilder/aacc/aacc_ui_test -oi -dp 20
  """
  import Enum
  import DefMemo

  @result_filename __DIR__ <> "/diagram/data/force.csv"

  def main(args) do
    parsed = args |> parse_args
    #IO.inspect parsed
    File.rm(@result_filename)
    {:ok, file} = @result_filename |> File.open([:read, :write])
    unless parsed[:tree], do: IO.write(file, "source,target,value\n")
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
    {time, struct} = :timer.tc(__MODULE__, :get_imports, [root_filename, 0, options])
    IO.puts "Took #{time/1_000_000}s"
    {:ok, rez} = Poison.encode(struct)
    IO.write(file, rez)
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

  defmemo get_imports(filename, level, options) do
    # Extracting options
    depth = options.max_depth
    only_inner_files = options.onlyinner
    results_file = options.file
    root_folder = options.root_folder
    folders = options.folders
    treeform = options.treeform

    if depth > level && searchable?(filename, root_folder, only_inner_files) do
      
      path = 
        get_file_path(filename, folders)
        get_imported_files(path, filename, root_folder, only_inner_files, treeform, options, level)
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

  defp get_init_struct(filename, treeform, root_folder, only_inner_files, options, level) do
    init_acc = if treeform do
      %{name: filename, children: []}
    else
      []
    end

    add_new_result = get_new_result_adder(filename, treeform, root_folder, only_inner_files, options, level)

    %{acc: init_acc, add_result: add_new_result}
  end

  defp get_new_result_adder(filename, treeform, root_folder, only_inner_files, options, level) do
    fn acc, next_filename ->  
      if searchable?(next_filename, root_folder, only_inner_files) do
        if treeform do
            %{
              name: acc.name,
              children: [get_imports(next_filename, level + 1, options) | acc.children]
            }
        else
            result = get_result_line(filename, next_filename)
            [result | acc]
        end
      else
        acc
      end
    end
  end

  defp get_imported_files(path, filename, root_folder, only_inner_files, treeform, options, level) do
    init = get_init_struct(filename, treeform, root_folder, only_inner_files, options, level);
    reduce_while(
      File.stream!(path, [], :line),
      init.acc,
      fn line, acc ->
        cond do
          is_import_line?(line) ->
            next_filename = line |> get_filename
            {:cont, init.add_result.(acc, next_filename)}
          empty?(acc.children) -> {:cont, acc}
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