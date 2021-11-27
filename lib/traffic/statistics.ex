defmodule Traffic.Statistics do
  alias Traffic.MemoryDB

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
    MemoryDB.update(table_name(simulation_name), vehicle_name, {wait_time, 0}, fn
      {old_wait_time, count} ->
        {old_wait_time + wait_time, count + 1}
    end)
  end

  def get_average_wait_time(simulation_name) do
    simulation_name
    |> table_name()
    |> MemoryDB.get_all_values()
    |> Enum.reduce({0, 0}, fn {sum, count}, {acc_sum, acc_count} ->
      {sum + acc_sum, count + acc_count}
    end)
    |> average()
  end

  def average({_sum, 0}) do
    0
  end

  def average({sum, count}) do
    sum / count
  end
end
