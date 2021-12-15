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

    try do
      :ets.new(__MODULE__, [:set, :named_table, :public])
    rescue
      _ ->
        nil
    end

    :ets.insert(__MODULE__, {table_name, table_name})
  end

  @doc """
  Destroys all tables
  """
  def destroy_tables do
    tables = :ets.select(__MODULE__, [{{:_, :"$1"}, [], [:"$1"]}])

    for table <- tables do
      :ets.delete_all_objects(table)
    end
  end

  @spec clear_table(atom | :ets.tid()) :: true
  def clear_table(table_name) do
    :ets.delete_all_objects(table_name)
  end

  @spec drop_table(atom | :ets.tid()) :: true
  def drop_table(table_name) do
    :ets.delete(table_name)
  end

  @doc """
  Retrieve the value with the given key from the named table.
  """

  def get(table, id) when is_binary(table) do
    get(String.to_existing_atom(table), id)
  end

  def get(table, id) do
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
  def insert(table, at \\ nil, record)

  def insert(table, at, record) when is_binary(table) do
    insert(String.to_existing_atom(table), at, record)
  end

  def insert(table, at, record) do
    :ets.insert(table, {at, record})
  end

  @doc """
  Update a value in the named table.
  """
  def update(table, at, default, update_fn)

  def update(table, at, default, update_fn) when is_binary(table) do
    update(String.to_existing_atom(table), at, default, update_fn)
  end

  def update(table, at, default, update_fn) do
    case get(table, at) do
      {:ok, value} ->
        insert(table, at, update_fn.(value))

      _ ->
        insert(table, at, default)
    end
  end

  @doc """
  Delete a value from a named table.
  """
  def delete(table, id) do
    :ets.delete(table, id)
  end
end
