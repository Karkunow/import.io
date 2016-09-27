defmodule ImportRepeat do
  
  import Enum, only: [
    reduce: 3,
    map: 2,
    at: 2,
    find: 3,
    uniq: 1,
    filter: 2,
    member?: 2
  ]

  import CommonTools, only: [is_empty_string?: 1]
  import TreeTools, only: [get_all_children_names: 1]
  alias Control.Functor

  def fill_in_repeated(tree, max_level) do
    level_repeats = calculate_repeats_by_level(tree, max_level)
    #IO.inspect level_repeats
    tree |> Functor.fmap(
      fn node ->
        %TreeNode{
          name: node.name,
          children: node.children,
          level: node.level,
          line: node.line,
          parent_name: node.parent_name,
          repeated:
            find(
              level_repeats |> at(node.level),
              {"", []},
              fn item -> item |> elem(0) === {node.name, node.parent_name} end
            ) |> elem(1)
        }
      end
    )
  end

  defp calculate_repeats_by_level(tree, max_level) do
    # In the end we're adding empty array for root node and the last layer which is not
    # needed to be calculated
    calculate_repeats_base(tree, 0, max_level, Map.new())
    |> Map.values # deleting Map keys, we now need only values array
    |> add_first_and_last
  end

  defp calculate_repeats_base(node, level, max_level, result_as_map) do
    node.children
    |> get_children_complements
    |> convert_complements_to_repeats
    |> recurse_in_depth(node.children, level, max_level, result_as_map)
  end

  defp add_first_and_last(array) do
    [[]] ++ array ++ [[]]
  end

  defp recurse_in_depth(_, nil, _, _, result_as_map), do: result_as_map

  defp recurse_in_depth(_, _, level, max_level, result_as_map)
    when level + 1 == max_level, do: result_as_map

  defp recurse_in_depth(repeat_tuples, children, level, max_level, result_as_map) do
    children
    |> reduce(
      Map.update(result_as_map, level, repeat_tuples, fn item -> uniq(item ++ repeat_tuples) end),
      fn child, old_repeats ->
        new_repeats = calculate_repeats_base(child, level + 1, max_level, old_repeats)
        Map.merge(old_repeats, new_repeats,
          fn _key, v1, v2 ->
            uniq(v1 ++ v2)
          end
        )
      end
    )
  end

  defp get_children_complements(nodes) do
    map(nodes,
      fn node ->
        {node, nodes |> filter(fn item ->  node.name !== item.name end)}
      end
    )
  end

  defp convert_complements_to_repeats(children_complements) do
    children_complements
    |> map(
      fn complement ->
        case complement do
          {module, children} ->
            {
              {module.name, module.parent_name},
              module |> find_where_module_repeats(children)
            }
          module -> {{module.name, module.parent_name}, false}
        end
      end
    )
  end

  defp find_where_module_repeats(module, children) do
    children
    |> map(fn child -> check(child, module.name) end)
    |> filter(fn item -> !is_empty_string?(item) end)
  end

  defp check(node_for_search, module_name) do
    cond do
      !node_for_search -> ""
      node_for_search.name === module_name -> ""
      node_for_search.name !== module_name ->
        names = get_all_children_names(node_for_search)
        if member?(names, module_name) do
          node_for_search.name
        else
          ""
        end
    end
  end
end