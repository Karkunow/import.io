defmodule Benchmark do
  
  import CommonTools

  @spec benchmark(module, atom, [any]) :: any
  def benchmark(module, function_name, args) do
    benchmark("", module, function_name, args)
  end

  @spec benchmark(module, atom, [any], String.t) :: any
  def benchmark(task_name, module, function_name, args) do
    final_name = process_task_name(task_name)
    {time, result} = :timer.tc(module, function_name, args)
    time = time/1_000_000
    IO.puts "#{final_name}took #{time}s"
    {time, result}
  end

  defp process_task_name(task_name) do
    if is_empty_string?(task_name) do
      "Task "
    else
      "'" <> task_name <> "' "
    end
  end
end