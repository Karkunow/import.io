defmodule CommonTools do
	import Enum, only: [take: 2, count: 1]

	def is_empty_string?(string), do: String.trim(string) == ""
	def remove_last(enumerable), do: enumerable |> take(count(enumerable) - 1)
end