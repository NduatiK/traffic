defmodule Traffic.Vehicles.Vehicle do
  use TypedStruct
  alias Traffic.Vehicles.DriverProfile
  alias __MODULE__

  typedstruct do
    # Self awareness
    @doc """
    Units per time
    """
    field(:id, integer(), default: 0)
    field(:speed, integer(), default: 0)
    field(:driver_profile, DriverProfile.t())

    # Location awareness
    # field(:road, pid())
    # field(:junction, pid())

    # Visual knowledge
    field(:visual_knowledge, map,
      default: %{
        vehicle_appx_dist: [],
        junction_appx_dist: []
      }
    )

    # field(:vehicle_appx_dist, list({pid(), integer()}))
    # field(:junction_appx_dist, {pid(), integer()})

    field(:marker, String.t())
  end

  def random() do
    speed = round(10 * (:rand.uniform_real() * 2)) / 10 + 0.1
    id = :rand.uniform(100_000)

    %Vehicle{
      id: id,
      driver_profile: DriverProfile.default(),
      # speed: :rand.uniform(4),
      speed: speed,
      marker: "#{round(speed)}"
      # marker: Enum.random(String.graphemes("◂▴◦▾◊"))
    }
  end

  def random(driver_profile_generator) do
    %DriverProfile{} = profile = DriverProfile.random(driver_profile_generator)

    speed = profile.mean_speed
    id = :rand.uniform(100_000)

    %Vehicle{
      id: id,
      driver_profile: profile,
      # speed: :rand.uniform(4),
      speed: speed,
      marker: "#{round(speed)}"
      # marker: Enum.random(String.graphemes("◂▴◦▾◊"))
    }
  end

  def start_moving() do
  end

  def slow_down(_vehicle) do
  end

  def avoid_collision(vehicle, comparative_speed) do
    if comparative_speed == :lt do
      slow_down(vehicle)
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
