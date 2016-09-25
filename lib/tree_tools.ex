defmodule TreeTools do
  import Enum
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

  defp check(node_for_search, module_name) do
    cond do
      !node_for_search -> false
      node_for_search.name === module_name -> false
      node_for_search.name !== module_name ->
        names = get_all_children_names(node_for_search)
        member?(names, module_name)
    end
  end

  def calculate_repeating(node) do
    calculate_repeating_base(node, node, 0)
  end

  defp calculate_repeating_base(root, current_node, level) do
    #root |> Functor.fmap(
      #fn node ->
        #%TreeNode{
          #name: node.name,
          #children: node.children,
          #repeated: calc_repeated(root, node)
        #}
      #end
    #)
  end
end