defmodule Traffic.MemoryDB do
  @moduledoc """
  A simple ETS based dB.
  """

  @doc """
  Create the tables listed in the @tables attribute
  """
  def create_table(table_name) when is_binary(table_name),
    do: String.to_atom(table_name)

  def create_table(table_name) do
    :ets.new(table_name, [:set, :named_table, :public])

    # :ets.insert(table_name, {"count", 0, "metadata"})

    catalogue = :ets.new(__MODULE__, [:set, :named_table])
    :ets.insert(catalogue, {table_name, table_name})
  end

  @doc """
  Destroys all tables
  """
  def destroy_tables do
    tables = :ets.select(__MODULE__, [{{:_, :"$1"}, [], [:"$1"]}])
    IO.inspect(tables)

    for table <- tables do
      :ets.delete_all_objects(table)
    end
  end

  def destroy_table(table_name) do
    :ets.delete_all_objects(table_name)
  end

  @doc """
  Retrieve the value with the given key from the named table.
  """

  def get(id, table) when is_binary(table) do
    get(id, String.to_existing_atom(table))
  end

  def get(id, table) do
    # :ets.lookup(table, id)

    case :ets.lookup(table, id) do
      [] -> {:error, "does not exist"}
      [{_key, record} | _] -> {:ok, record}
    end
  end

  @doc """
  Retrieve all values from the named table.
  """
  def get_all_values(table) when is_binary(table) do
    get_all_values(String.to_existing_atom(table))
  end

  def get_all_values(table) do
    # Select from the table the second item in the kv pair,
    # apply no filters
    # return the value
    :ets.select(table, [{{:_, :"$1"}, [], [:"$1"]}])
  end

  @doc """
  Retrieve all kv pairs from the named table.
  """
  def get_all(table) when is_binary(table) do
    get_all(String.to_existing_atom(table))
  end

  def get_all(table) do
    :ets.select(table, [{:"$1", [], [:"$1"]}])
  end

  @doc """
  Insert a value into the named table.
  """
  def insert(record, table, at \\ nil)

  def insert(record, table, at) when is_binary(table) do
    insert(record, String.to_existing_atom(table), at)
  end

  def insert(record, table, at) do
    :ets.insert(table, {at, record})
  end

  @doc """
  Delete a value from a named table.
  """
  def delete(id, table) do
    :ets.delete(table, id)
  end
end
