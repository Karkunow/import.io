defmodule ImportOptions do
  defstruct [:root_file, :folders, :inner_search, :is_tree, :max_depth]
end

defmodule TreeNode do
  defstruct [:name, :children, :repeated]
end

alias Control.Functor

defimpl Functor, for: TreeNode do
  def fmap(tree, fun) do
    fun.(
      %TreeNode{
        name: tree.name,
        children: if tree.children do
          Enum.map(tree.children, fn child -> Functor.fmap(child, fun) end)
        else
          []
        end,
        repeated: tree.repeated
      }
    )
  end
end

defimpl Enumerable, for: TreeNode do
  def count(tree) do
    {:ok,
      tree |> Enum.reduce(0, fn item, acc -> acc + 1 end)
    }
  end

  def member?(tree, item_to_find) do
    {:ok,
      tree |> Enum.reduce(false, fn item, acc -> item_to_find === item end)
    }
  end

  def reduce(tree, {:cont, acc}, fun) do
    new_acc = fun.(tree, acc)
    if tree.children do
      tree.children |> Enum.reduce(new_acc,
        fn item, acc ->
          reduce(item, acc, fun)
        end
      )
    else
      new_acc
    end
  end
end
