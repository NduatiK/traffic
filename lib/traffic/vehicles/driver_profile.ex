defmodule Traffic.Vehicles.DriverProfile do
  use TypedStruct
  alias __MODULE__
  alias Traffic.Network.Config

  typedstruct do
    # in Km.h
    field :name, atom(), enforce: true
    field :mean_speed, float(), enforce: true
    field :speed_std_dev, float(), default: 5
    # in Km.h/s, default: Up to 60 KpH in 15 seconds
    field :initial_acceleration, float(), default: 60 / 15

    # in m, default: 5
    field :distance_from_lead, float(), default: 5
  end

  def default() do
    %DriverProfile{
      name: :default,
      mean_speed: 40,
      initial_acceleration: 50 / 15
    }
  end

  def default_fast() do
    %DriverProfile{
      name: :default_fast,
      mean_speed: 50,
      initial_acceleration: 60 / 15
    }
  end

  def random(mean, std) do
    %DriverProfile{
      name: :random,
      mean_speed: gauss(mean, std),
      speed_std_dev: std,
      initial_acceleration: 50 / 15
    }
  end

  def tailgater do
    %DriverProfile{
      name: :tailgater,
      mean_speed: gauss(50, 10),
      speed_std_dev: 10,
      initial_acceleration: 50 / 15,
      distance_from_lead: 1
    }
  end

  def planner do
    %DriverProfile{
      name: :planner,
      mean_speed: gauss(50, 10),
      speed_std_dev: 10,
      initial_acceleration: 50 / 15,
      distance_from_lead: 3
    }
  end

  def flow_conformist do
    %DriverProfile{
      name: :flow_conformist,
      mean_speed: gauss(40, 5),
      speed_std_dev: 5,
      initial_acceleration: 50 / 15,
      distance_from_lead: 3
    }
  end

  def extremist do
    %DriverProfile{
      name: :extremist,
      mean_speed: gauss(40, 20),
      speed_std_dev: 20,
      initial_acceleration: 50 / 15,
      distance_from_lead: 3
    }
  end

  def ultra_conservative do
    %DriverProfile{
      name: :ultra_conservative,
      mean_speed: gauss(20, 20),
      speed_std_dev: 20,
      initial_acceleration: 15 / 15,
      distance_from_lead: 3
    }
  end

  def gauss(%DriverProfile{mean_speed: mean, speed_std_dev: std}),
    do: max(0, :rand.normal(mean, std))

  defp gauss(mean, std), do: max(0, :rand.normal(mean, std))

  @profiles [
    {&__MODULE__.tailgater/0, :tailgater},
    {&__MODULE__.planner/0, :planner},
    {&__MODULE__.flow_conformist/0, :flow_conformist},
    {&__MODULE__.extremist/0, :extremist},
    {&__MODULE__.ultra_conservative/0, :ultra_conservative}
  ]

  @profile_count Enum.count(@profiles)

  def default_stats() do
    @profiles
    |> Enum.map(fn {_, name} -> {name, 0.6} end)
    |> Enum.into(%{})
  end

  @doc """
  random(%{
    tailgater: 0.7,
    planner: 0.7,
    flow_conformist: 0,
    extremist: 0,
    ultra_conservative: 0
  }) would only produce tailgaters and planners with equal probability

  If the stat is unassigned, we give it 0.5
  If all the stats are 0, we give each 0.5
  """
  def random(%{driver_profile_stats: stats}) do
    random(stats)
  end

  def random(stats) do
    profile =
      if invalid_stats?(stats) do
        do_random(default_stats())
      else
        do_random(stats)
      end

    IO.inspect(profile.name)
    profile
  end

  defp invalid_stats?(stats) do
    map_size(stats) == @profile_count and Enum.all?(stats, fn {_, v} -> v <= 0 end)
  end

  defp do_random(stats) do
    distribution =
      @profiles
      |> Enum.map(&get_stat(&1, stats))

    distribution_range =
      distribution
      |> Enum.map(&elem(&1, 1))
      |> Enum.sum()

    random_number = :rand.uniform_real() * distribution_range

    distribution =
      distribution
      |> find_profile_at(random_number)
      |> then(fn generator -> generator.() end)
  end

  defp get_stat({generator, name}, stats, default \\ 0.5) do
    {generator,
     stats
     |> Map.get(name, default)
     |> clamp(0, 1)}
  end

  defp find_profile_at(distribution, random_number) do
    distribution
    |> Enum.reduce_while(0, fn
      # stop when the the random number is between
      # the upper and lower bounds of the profile
      {generator, size}, lower_bound when random_number <= lower_bound + size ->
        {:halt, generator}

      # otherwise move to next profile
      {_, size}, lower_bound ->
        {:cont, lower_bound + size}
    end)
  end

  defp clamp(num1, min_value, max_value) do
    num1
    # At the very most take the max value
    |> min(max_value)
    # At the very least take the min value
    |> max(min_value)
  end
end
