defmodule Traffic.Network.Config do
  alias Traffic.Vehicles.DriverProfile
  alias Traffic.Network.Timing.Strategy

  use TypedStruct

  # Enforce keys by default.
  typedstruct enforce: true do
    field :driver_profile_stats, map(), default: DriverProfile.default_stats()
    field :timing_strategy, Strategy
  end
end
