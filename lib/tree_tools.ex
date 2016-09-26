defmodule TreeTools do
  import Enum

  # PUBLIC FUNCTIONS

	def get_all_children(node) do
    get_all_children_base(node, &(&1))
	end

  def get_all_children_names(node) do
    get_all_children_base(node, &(&1.name))
  end

  def get_tree_levels(tree) do
    get_tree_levels_base(tree, 0, &get_children_on_level/2)
  end

  def get_tree_level_names(tree) do
    get_tree_levels_base(tree, 0, &get_names_on_level/2)
  end

  def get_children_on_level(node, level) do
    get_children_on_level_base(node, &(&1), level, 0)
  end

  def get_names_on_level(node, level) do
    get_children_on_level_base(node, &(&1.name), level, 0)
  end

  # PRIVATE FUNCTIONS

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

  defp get_tree_levels_base(tree, level, level_fn) do
    children = level_fn.(tree, level)
    if count(children) > 0 do
      [children] ++ get_tree_levels_base(tree, level + 1, level_fn)
    else
      []
    end
  end

end