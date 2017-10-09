defmodule Importio do
  @moduledoc """
    Usage example:
      escript importio -rf "C:/flowapps, C:/flow/lib" -f smartbuilder/binrunner -dp 5 -oi --tree
  """
  import Enum
  import DefMemo
  import Benchmark
  import ImportTools
  import CommonTools

  def main(args) do

    options = args |> parse_args
    {time1, imports} = benchmark("Calculating imports structure", __MODULE__, :get_imports_structure, [options])
    {time2, imports_with_repeated} =
      if options.is_tree do 
        benchmark(
          "Calculating repeats in the imports tree",
          ImportRepeat,
          :fill_in_repeated,
          [imports, options.cleaned_level, options.max_depth]
        )
      else
        {0.0, imports}
      end

    {time3, _} = benchmark(
      "Writing to file",
      __MODULE__,
      :save_result,
      [imports_with_repeated, options.is_tree, options.dot]
    )

    {time4, _} = benchmark(
      "Removing un-needed imports",
      __MODULE__,
      :cleanup_repeated_modules,
      [imports_with_repeated, options.folders, options.cleanup]
    )

    IO.puts "Total running time: #{time1 + time2 + time3 + time4}s"
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
        dot: :boolean,
        depth: :integer,
        cleaned_level: :integer,
        cleanup: :boolean
      ],
      aliases: [
        rf: :root_folders,
        f: :file,
        oi: :inner_search,
        dp: :depth,
        cl: :cleaned_level
      ]
    )
    parsed = options |> transform_options.()
    filter_nil = fn x -> if is_nil(x), do: false, else: x end
    dot_value = filter_nil.(parsed[:dot])
    cleanup_value = filter_nil.(parsed[:cleanup])
    tree_value = filter_nil.(parsed[:tree]) || cleanup_value
    inner_search_value = filter_nil.(parsed[:inner_search])

    %ImportOptions{
      root_file: parsed[:file],
      folders: parsed[:root_folders],
      inner_search: inner_search_value,
      is_tree: tree_value,
      max_depth: parsed[:depth],
      cleanup: cleanup_value,
      cleaned_level: parsed[:cleaned_level],
      dot: dot_value
    }
  end

  def save_result(result, is_tree, need_dot_file) do
    result_filename = Path.expand("data/force.csv")
    if File.exists?(result_filename) do
      File.rm!(result_filename)
    else
      File.mkdir!("data")
      File.touch!(result_filename, :calendar.universal_time())
    end
    file = result_filename |> File.open!([:read, :write])
    {:ok, rez} =
      cond do
        not (is_tree or need_dot_file) ->
          IO.write(file, "source,target,value\n")
          {:ok, result}
        need_dot_file ->
          IO.write(file, "strict digraph {\n")
          {:ok, result}
        true ->
          result |> Poison.encode
      end
    IO.write(file, rez)
    if need_dot_file do
      IO.write(file, "}")
    end
    File.close(file)
    if need_dot_file do
      executable_extension =
        case :os.type do
          {:unix, _} -> ""
          _ -> ".exe"
        end
      System.cmd("dot" <> executable_extension, ["-Tjpg",  "data/force.csv", "-o" <> "data/graph.jpg", "-Gdpi=144"])
    end
  end

  def get_imports_structure(options) do
    get_imports_structure(options.root_file, 0, 0, "", options)
  end

  defmemo get_imports_structure(filename, level, line_number, parent_name, options) do
    # Extracting options
    #max_depth = options.max_depth
    #inner_search = options.inner_search
    root_folder = get_root_folder(options.root_file, options.folders)
    folders = options.folders
    is_tree = options.is_tree

    path = get_file_path(filename, folders)
    #IO.puts path
    init = get_init_struct(filename, level, line_number, parent_name, options);

    if searchable?(filename, level, options) do
      scan_imports_structure(path, init, is_tree) |> elem(1)
    else
      init.acc |> elem(1)
    end
  end

  @doc """
    Scans for imports inside file determined by the path.
    Supposes that all imports are written in the one text block
    if algo encounters some import and then the line with some other text
    then it stops searching through file
  """
  def scan_imports_structure(path, init, is_tree) do
    #IO.puts "Start scan in " <> path
    reduce_while(
      File.stream!(path),
      init.acc,
      fn line, acum ->
        {line_number, acc} = acum
        cond do
          is_import_line?(line) ->
            next_filename = line |> get_dir_filename
            {:cont, {line_number + 1, init.add_result.(acc, line_number, next_filename)}}
          is_empty_acc?(acc, is_tree) -> {:cont, {line_number + 1, acc}}
          is_empty_string?(line) -> {:cont, {line_number + 1, acc}}
          is_comment_line?(line) -> {:cont, {line_number + 1, acc}}
          true -> {:halt, {line_number + 1, acc}}
        end
      end
    )
  end

  defp get_init_struct(filename, level, line_number, parent_name, options) do
    init_acc = 
      if options.is_tree do
        {0,
          %TreeNode{
            name: filename,
            children: [],
            level: level,
            line: line_number,
            parent_name: parent_name
          }
        }
      else
        {0, []}
      end

    add_new_result = get_new_result_adder(filename, level, line_number, parent_name, options)

    %{acc: init_acc, add_result: add_new_result}
  end

  defp get_new_result_adder(filename, level, parent_line_number, parent_name, options) do
    fn acc, new_line_number, next_filename ->  
      if searchable?(next_filename, level, options) do
        if options.is_tree do
            %TreeNode{
              name: acc.name,
              children: [get_imports_structure(next_filename, level + 1, new_line_number, filename, options) | acc.children] |> List.flatten,
              level: level,
              line: parent_line_number,
              parent_name: parent_name
            }
        else
            result = get_result_line(filename, next_filename, options.dot, get_root_folder(options.root_file, options.folders))
            new_array = [result | acc]
            new = get_imports_structure(next_filename, level + 1, 0, "", options)
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

  defp get_result_line(filename, next_filename, need_dot_file, root_folder) do
    cond do
      need_dot_file ->
        pl = String.length(root_folder)
        sliceIf = fn fname -> 
          if String.starts_with?(fname, root_folder) do
            "\"" <> String.slice(fname, pl + 1, String.length(fname) - pl) <> "\""
          else
            "\"" <> fname <> "\""
          end
        end;

        line = ["\t", sliceIf.(filename), "->", sliceIf.(next_filename)] |> join(" ")
        line <> ";\n"
      not need_dot_file ->
        [filename, next_filename, "0.2\n"] |> join(",")
    end
  end

  def cleanup_repeated_modules(tree_with_repetitions, folders, do_cleanup) do
    if do_cleanup do
      tree_with_repetitions
      |> Enum.reduce(Map.new(),
        fn node, acc ->
          if count(node.repeated) > 0 do
            Map.update(acc,
              node.parent_name,
              [node.line],
              &(uniq(&1 ++ [node.line]))
            )
          else
            acc
          end
        end
      )
      |> Map.to_list
      |> remove_lines_from_files(folders)
    end
  end

  defp remove_lines_from_files(filelist, folders) do
    filelist
    |> Enum.each(
      fn {pname, lines} ->
          FileTools.remove_lines(
            get_file_path(pname, folders),
            lines
          )
      end
    )
  end

end