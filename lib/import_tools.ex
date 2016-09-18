defmodule ImportTools do
  import Enum
  import CommonTools
  @moduledoc """
    Provides tools for imports-scanning function
  """
  def is_import_line?(line) do
    line |> String.starts_with?("import")
  end

  @doc """
    Gets filename with with directories from the import line
  """
  def get_dir_filename(line) do
    "import " <> rest = line
    String.split(rest, ";", [trim: true]) |> at(0)
  end

  @doc """
    Gets root folder from filename with directories
  """
  def get_root_folder(dir_filename) do
    remove_last = fn words ->
      slice(words, 0, count(words) - 1)
    end

    String.split(dir_filename, "/")
    |> remove_last.()
    |> join("/")
  end

  @doc """
    Checks if file with 'filename' is searchable: which means we can scan imports from it
  """
  def searchable?(filename, current_level, options) do
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