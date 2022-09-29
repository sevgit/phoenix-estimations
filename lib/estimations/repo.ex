defmodule Estimations.Repo do
  use Ecto.Repo,
    otp_app: :estimations,
    adapter: Ecto.Adapters.Postgres
end
