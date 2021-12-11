defmodule Traffic.Statistics do
  alias Traffic.MemoryDB
  @queue_len 10
  def table_name(simulation_name), do: :"#{__MODULE__}.#{simulation_name}"

  def start_up(simulation_name) do
    MemoryDB.create_table(table_name(simulation_name))
  end

  def reset(simulation_name) do
    try do
      MemoryDB.drop_table(table_name(simulation_name))
    rescue
      _ ->
        nil
    end

    start_up(simulation_name)
  end

  def update_wait_time(simulation_name, vehicle_name, wait_time) do
    queue = :queue.from_list(List.duplicate(wait_time, @queue_len))

    MemoryDB.update(
      table_name(simulation_name),
      vehicle_name,
      queue,
      fn
        queue ->
          wait_time
          |> :queue.in(queue)
          |> :queue.drop()
      end
    )
  end

  def get_average_wait_time(simulation_name) do
    vehicles =
      simulation_name
      |> table_name()
      |> MemoryDB.get_all_values()

    # start

    vehicles
    |> Enum.reduce(
      {0, 0},
      fn queue, {acc_sum, acc_count} ->
        sum = queue |> :queue.to_list() |> Enum.sum()
        {sum + acc_sum, @queue_len + acc_count}
      end
    )
    |> average()
    |> round(2)
  end

  def average({_sum, 0}) do
    0
  end

  def average({sum, count}) do
    sum / count
  end

  def round(num, dp) do
    round(num * :math.pow(10, dp)) / :math.pow(10, dp)
  end
end
