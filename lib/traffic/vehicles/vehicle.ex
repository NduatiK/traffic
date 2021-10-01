defmodule Traffic.Vehicles.Vehicle do
  use TypedStruct
  alias Traffic.Vehicles.DriverProfile

  typedstruct do
    # Self awareness
    field :speed, integer(), default: 0
    field :driver_profile, DriverProfile.t()

    # Location awareness
    field :location_on_road, float(), enforce: true
    field :road, pid()
    field :junction, pid()

    # Visual knowledge
    field :vehicle_appx_dist, list({pid(), integer()})
    field :junction_appx_dist, {pid(), integer()}
  end

  def start_moving() do
  end

  def slow_down() do
  end

  def avoid_collision(vehicle, comparative_speed) do
    if comparative_speed == :lt do
      slow_down()
    end
  end

  def join_junction(_junction_pid, _exit_road) do
  end

  def update_vision() do
  end

  def change_lane() do
  end

  def look_ahead() do
  end
end

defimpl Inspect, for: Traffic.Vehicles.Vehicle do
  def inspect(vehicle, _opts) do
    "X"
  end
end
