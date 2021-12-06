defmodule Traffic.SimulationList do
  use GenServer
  alias Traffic.Network.NetworkSupervisor

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_opts) do
    schedule_poll()

    {:ok, []}
  end

  def add_simulation({name, data}) do
    GenServer.cast(__MODULE__, {:add_simulation, {name, data}})
  end

  def remove_simulation(name) do
    GenServer.cast(__MODULE__, {:remove_simulation, name})
  end

  def get_list() do
    GenServer.call(__MODULE__, :get_list)
  end

  def handle_cast({:add_simulation, {name, data}}, state) do
    [{name, data} | state]
    |> then(&{:noreply, &1})
  end

  def handle_cast({:remove_simulation, name}, state) do
    state
    |> Enum.reject(fn {name_in_list, _pid} ->
      name_in_list == name
    end)
    |> then(&{:noreply, &1})
  end

  def handle_call(:get_list, _, state) do
    {:reply, state, state}
  end

  def handle_info(:poll_simulations, state) do
    schedule_poll()

    state
    |> Enum.filter(fn {_name, info} ->
      GenServer.whereis(info.via)
      # Process.alive?(pid)
    end)
    |> then(&{:noreply, &1})
  end

  def schedule_poll() do
    Process.send_after(self(), :poll_simulations, 1000)
  end
end
