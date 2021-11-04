defmodule Traffic.Network.Config do
  alias Traffic.Vehicles.DriverProfile

  defstruct driver_profile_stats: DriverProfile.default_stats()
end
