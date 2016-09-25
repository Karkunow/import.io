defmodule TreeTools do
  import Enum
  import CommonTools
  alias Control.Functor

	def get_all_children(node) do
    get_all_children_base(node, &(&1))
	end

  def get_all_children_names(node) do
    get_all_children_base(node, &(&1.name))
  end

  defp get_all_children_base(node, transform_child) do
    if node.children do
      node.children |> reduce([],
        fn child, acc ->
          acc ++ [transform_child.(child)] ++ get_all_children_base(child, transform_child)
        end
      )
    else
      []
    end
  end

  def get_children_on_level(node, level) do
    get_children_on_level_base(node, &(&1), level, 0)
  end

  def get_names_on_level(node, level) do
    get_children_on_level_base(node, &(&1.name), level, 0)
  end

  defp get_children_on_level_base(node, transform_child, level, current_level) do
    cond do
      current_level > level -> []
      !node.children -> []
      current_level == level ->
        node.children |> map(
          fn child ->
            transform_child.(child)
          end
        )
      current_level < level ->
        node.children |> reduce([],
          fn child, acc ->
            acc ++ get_children_on_level_base(child, transform_child, level, current_level + 1)
          end
        )
    end
  end

  def get_tree_levels(tree) do
    get_tree_levels_base(tree, 0, &get_children_on_level/2)
  end

  def get_tree_level_names(tree) do
    get_tree_levels_base(tree, 0, &get_names_on_level/2)
  end

  defp get_tree_levels_base(tree, level, level_fn) do
    children = level_fn.(tree, level)
    if count(children) > 0 do
      [children] ++ get_tree_levels_base(tree, level + 1, level_fn)
    else
      []
    end
  end

  def fill_in_repeated(tree) do
    level_repeats = calculate_repeats_by_level(tree)
    tree |> Functor.fmap(
      fn node ->
        %TreeNode{
          name: node.name,
          children: node.children,
          level: node.level,
          repeated:
            member?(
              level_repeats |> at(node.level),
              {node.name, true}
            )
        }
      end
    )
  end

  def calculate_repeats_by_level(tree) do
    tree
    |> get_tree_levels
    |> get_children_complements
    |> remove_last
    |> get_repeated_modules_by_level
    |> add_first_and_last
  end

  defp add_first_and_last(array) do
    [[]] ++ array ++ [[]]
  end

  defp get_repeated_modules_by_level(child_complements) do
    child_complements
    |> map(
      fn level_array ->
        level_array
        |> map(
          fn level_item ->
            case level_item do
              {module, children} -> {module.name, children |> map(fn child -> check(child, module.name) end) |> any?}
              _ -> {level_item.name, false}
            end
          end
        )
        |> filter(&(&1 |> elem(1)))
      end
    )
  end

  defp get_children_complements(levels) do
    levels |> map(
      fn lvl ->
        map(lvl, fn l ->
          {l, filter(lvl, fn item ->  l.name != item.name end)}
        end)
      end
    )
  end

  defp check(node_for_search, module_name) do
    cond do
      !node_for_search -> false
      node_for_search.name === module_name -> false
      node_for_search.name !== module_name ->
        names = get_all_children_names(node_for_search)
        member?(names, module_name)
    end
  end
end