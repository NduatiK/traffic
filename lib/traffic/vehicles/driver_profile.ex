defmodule Traffic.Vehicles.DriverProfile do
  use TypedStruct
  alias __MODULE__

  typedstruct do
    # in Km.h
    field :mean_speed, float(), enforce: true
    field :speed_std_dev, float(), default: 5
    # in Km.h/s, default: Up to 60 KpH in 15 seconds
    field :initial_acceleration, float(), default: 60 / 15

    # in m, default: 5
    field :distance_from_lead, float(), default: 5
  end

  def default() do
  %DriverProfile{
      mean_speed: 40,
      initial_acceleration: 50 / 15
    }
  end

  def default_fast() do
    %DriverProfile{
      mean_speed: 50,
      initial_acceleration: 60 / 15
    }
  end

  def random(mean, std) do
    %DriverProfile{
      mean_speed: :rand.normal(mean, std),
      speed_std_dev: std,
      initial_acceleration: 50 / 15
    }
  end
end
