defmodule Importio do
  @moduledoc """
    Using example:
      escript importio -rf "C:/flowapps, C:/flow" -f smartbuilder/aacc/aacc_ui_test -oi -dp 20
  """
  import Enum
  import DefMemo
  import Benchmark
  import Tools

  def main(args) do
    options = args |> parse_args
    {time1, result1} = benchmark("Calculating imports structure", __MODULE__, :get_imports_structure, [options])
    {time2, _} = benchmark("Writing to file", __MODULE__, :save_result, [result1, options.is_tree])
    IO.puts "Total running time: #{time1 + time2}s"
  end

  defp parse_args(args) do
    transform_options= fn options ->
      root_folders_raw = options |> Keyword.get(:root_folders)
      root_folders = root_folders_raw |> String.split(", ")
      options |> Keyword.put(:root_folders, root_folders)
    end

    {options, _, _} = args |> OptionParser.parse(
      switches: [
        root_folders: :string,
        file: :string, 
        inner_search: :boolean,
        tree: :boolean,
        depth: :integer
      ],
      aliases: [
        rf: :root_folders,
        f: :file,
        oi: :inner_search,
        dp: :depth
      ]
    )
    parsed = options |> transform_options.()

    %ImportOptions{
      root_file: parsed[:file],
      folders: parsed[:root_folders],
      inner_search: parsed[:inner_search],
      is_tree: parsed[:tree],
      max_depth: parsed[:depth]
    }
  end

  def save_result(result, is_tree) do
    result_filename = __DIR__ <> "/diagram/data/force.csv"
    File.rm(result_filename)
    {:ok, file} = result_filename |> File.open([:read, :write])
    {:ok, rez} = unless is_tree do
      IO.write(file, "source,target,value\n")
      {:ok, result}
    else
      result |> Poison.encode
    end
    IO.write(file, rez)
    File.close(file)
  end

  def get_imports_structure(options) do
    get_imports_structure(options.root_file, 0, options)
  end

  defmemo get_imports_structure(filename, level, options) do
    # Extracting options
    max_depth = options.max_depth
    inner_search = options.inner_search
    root_folder = options.root_file |> get_root_folder
    folders = options.folders
    is_tree = options.is_tree

    path = get_file_path(filename, folders)
    init = get_init_struct(filename, level, options);

    if searchable?(filename, level, options) do
      scan_imports_structure(path, init, is_tree)
    else
      init.acc
    end
  end

  defp scan_imports_structure(path, init, is_tree) do
    reduce_while(
      File.stream!(path, [], :line),
      init.acc,
      fn line, acc ->
        # supposes that all imports are written in the one text block
        # if algo encounters some import and then the line with some other text
        # then it stops searching through file
        cond do
          is_import_line?(line) ->
            next_filename = line |> get_filename
            {:cont, init.add_result.(acc, next_filename)}
          is_empty_acc?(acc, is_tree) -> {:cont, acc}
          is_empty_string?(line) -> {:cont, acc}
          true -> {:halt, acc}
        end
      end
    )
  end

  defp get_root_folder(filename) do
    remove_last = fn words ->
      slice(words, 0, count(words) - 1)
    end

    String.split(filename, "/")
    |> remove_last.()
    |> join("/")
  end

  defp get_file_path(filename, root_folders) do
     raw_result = root_folders |> reduce_while({:error, ""},
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

  defp get_init_struct(filename, level, options) do
    init_acc = 
      if options.is_tree do
        %{name: filename, children: []}
      else
        []
      end

    add_new_result = get_new_result_adder(filename, level, options)

    %{acc: init_acc, add_result: add_new_result}
  end

  defp get_new_result_adder(filename, level, options) do
    fn acc, next_filename ->  
      if searchable?(next_filename, level, options) do
        if options.is_tree do
            %{
              name: acc.name,
              children: [get_imports_structure(next_filename, level + 1, options) | acc.children] |> List.flatten
            }
        else
            result = get_result_line(filename, next_filename)
            new_array = [result | acc]
            new = get_imports_structure(next_filename, level + 1, options)
            if new do
              Enum.concat(new, new_array)
            else
              new_array
            end
        end
      else
        acc
      end
    end
  end

  defp is_empty_acc?(acc, is_tree) do
    is_graph = !is_tree
    cond do
      is_tree  -> empty?(acc.children)
      is_graph -> empty?(acc)
    end
  end

  defp get_result_line(filename, next_filename), do: [filename, next_filename, "0.2\n"] |> join(",")

  defp get_filename(line) do
    "import " <> rest = line
    String.split(rest, ";", [trim: true]) |> at(0)
  end

  defp is_import_line?(line) do
    line |> String.starts_with?("import")
  end

  defp searchable?(filename, current_level, options) do
    searchable?(
      filename,
      options.root_file |> get_root_folder,
      options.inner_search,
      options.max_depth,
      current_level
    )
  end

  defp searchable?(filename, root_folder, inner_search, max_depth, current_level) do
    cond do
      max_depth == current_level -> false
      !inner_search -> true
      is_empty_string?(root_folder)-> false
      true -> filename |> String.starts_with?(root_folder)
    end
  end
end