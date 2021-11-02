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
      mean_speed: gauss(mean, std),
      speed_std_dev: std,
      initial_acceleration: 50 / 15
    }
  end

  def random do
    [
      {&tailgater/0, 0.5},
      {&planner/0, 0.5},
      {&flow_conformist/0, 0.5},
      {&extremist/0, 0.5},
      {&ultra_conservative/0, 0.5}
    ]
  end

  def tailgater do
    %DriverProfile{
      mean_speed: gauss(50, 10),
      speed_std_dev: 10,
      initial_acceleration: 50 / 15,
      distance_from_lead: 1
    }
  end

  def planner do
    %DriverProfile{
      mean_speed: gauss(50, 10),
      speed_std_dev: 10,
      initial_acceleration: 50 / 15,
      distance_from_lead: 3
    }
  end

  def flow_conformist do
    %DriverProfile{
      mean_speed: gauss(40, 5),
      speed_std_dev: 5,
      initial_acceleration: 50 / 15,
      distance_from_lead: 3
    }
  end

  def extremist do
    %DriverProfile{
      mean_speed: gauss(40, 20),
      speed_std_dev: 20,
      initial_acceleration: 50 / 15,
      distance_from_lead: 3
    }
  end

  def ultra_conservative do
    %DriverProfile{
      mean_speed: gauss(40, 20),
      speed_std_dev: 20,
      initial_acceleration: 50 / 15,
      distance_from_lead: 3
    }
  end

  def gauss(mean, std), do: max(0, :rand.normal(mean, std))
end
