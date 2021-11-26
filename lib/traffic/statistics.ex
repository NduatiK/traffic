defmodule Traffic.Statistics do
  alias Traffic.MemoryDB

  def table_name(simulation_name), do: :"#{__MODULE__}.#{simulation_name}"

  def start_up(simulation_name) do
    MemoryDB.create_table(table_name(simulation_name))
  end

  def reset(simulation_name) do
    MemoryDB.destroy_table(table_name(simulation_name))
    start_up(simulation_name)
  end

  def update_wait_time(simulation_name, vehicle_name, wait_time) do
    MemoryDB.insert(wait_time, table_name(simulation_name), vehicle_name)
  end

  def get_average_wait_time(simulation_name) do
    wait_times = MemoryDB.get_all_values(table_name(simulation_name))

    sum = Enum.sum(wait_times)

    sum / Enum.count(wait_times)
  end
end
