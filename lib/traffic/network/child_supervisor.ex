defmodule Traffic.Network.ChildSupervisor do
  use DynamicSupervisor
  alias Traffic.Network.RoadServer
  alias Traffic.Vehicles.VehicleServer
  alias Traffic.Network.JunctionServer

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg,
      name: Traffic.via_tuple(__MODULE__, Keyword.get(init_arg, :name))
    )
  end

  def start_road(supervisor, id, name, junction1, junction2, config) do
    spec =
      {RoadServer,
       [id: id, name: name, config: config, junction1: junction1, junction2: junction2]}

    DynamicSupervisor.start_child(supervisor, spec)
  end

  def start_junction(supervisor, id, name, x, y, config) do
    spec = {JunctionServer, [id: id, name: name, config: config, x: x, y: y]}
    DynamicSupervisor.start_child(supervisor, spec)
  end

  @spec start_vehicle(atom | pid | {atom, any} | {:via, atom, any}, any, any, any) ::
          :ignore | {:error, any} | {:ok, pid} | {:ok, pid, any}
  def start_vehicle(supervisor, id, name, config) do
    spec = {VehicleServer, [id: id, name: name, config: config]}
    DynamicSupervisor.start_child(supervisor, spec)
  end

  @impl true
  def init(init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [init_arg]
    )
  end

  def via(name) do
    Traffic.via_tuple(__MODULE__, name)
  end
end
