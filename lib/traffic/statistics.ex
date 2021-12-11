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

  @threshold 10

  def update_wait_time(simulation_name, vehicle_name, wait_time) do
    MemoryDB.update(table_name(simulation_name), vehicle_name, {wait_time, 0}, fn
      {old_wait_time, count} when count > @threshold ->
        {old_wait_time + wait_time, count + 1}

      {_old_wait_time, count} ->
        {0, count + 1}
    end)
  end

  def get_average_wait_time(simulation_name) do
    vehicles =
      simulation_name
      |> table_name()
      |> MemoryDB.get_all_values()

    # start

    vehicles
    |> Enum.reduce({0, -(Enum.count(vehicles) * @threshold)},
     fn {sum, count},                                                                 {acc_sum, acc_count} ->
      {sum + acc_sum, count + acc_count}
    end)
    |> average()
    |> round(2)
  end

  def average({_sum, count}) when count <= @threshold do
    0
  end

  def average({sum, count}) do
    sum / (count - @threshold)
  end

  def round(num, dp) do
    round(num * :math.pow(10, dp)) / :math.pow(10, dp)
  end
end
