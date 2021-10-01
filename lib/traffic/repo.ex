defmodule Traffic.Repo do
  use Ecto.Repo,
    otp_app: :traffic,
    adapter: Ecto.Adapters.Postgres
end
