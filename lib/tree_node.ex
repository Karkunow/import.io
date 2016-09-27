defmodule TreeNode do
  defstruct [:name, :children, :repeated, :level, :line, :parent_name]
end

alias Control.Functor

defimpl Functor, for: TreeNode do
  def fmap(tree, fun) do
    fun.(
      %TreeNode{
        name: tree.name,
        children: if Enum.count(tree.children) > 0 do
          Enum.map(tree.children, fn child -> Functor.fmap(child, fun) end)
        else
          []
        end,
        repeated: tree.repeated,
        level: tree.level,
        line: tree.line,
        parent_name: tree.parent_name
      }
    )
  end
end

defimpl Enumerable, for: TreeNode do
  def count(tree) do
    {:ok,
      tree |> Enum.reduce(0, fn _item, acc -> acc + 1 end)
    }
  end

  def member?(tree, item_to_find) do
    {:ok,
      tree |> Enum.reduce(false, fn item, _acc -> item_to_find === item end)
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