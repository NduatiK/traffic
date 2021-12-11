defmodule Traffic do
  @moduledoc """
  Traffic keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def via_tuple(module, unique_name) do
    {:via, Registry, {Registry.Traffic, {module, unique_name}}}
  end

  def via_tuple(module) do
    {:via, Registry, {Registry.Traffic, {module}}}
  end
end
