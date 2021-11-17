defmodule Traffic.Network.NetworkSupervisor do
  use Supervisor
  alias Traffic.Network.Manager
  alias Traffic.Network.ChildSupervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg,
      name: Traffic.via_tuple(__MODULE__, Keyword.get(init_arg, :name))
    )
  end

  @impl true
  def init(init_arg) do
    children = [
      {Manager, init_arg},
      {ChildSupervisor, init_arg}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
