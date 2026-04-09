defmodule EightDCore.Storage.Store do
  @moduledoc """
  A simple pluggable abstraction for storing immutable DAG nodes.
  For MVP, we use an in-memory ETS table or standard Map.
  """

  @callback put(String.t(), any()) :: :ok | {:error, term()}
  @callback get(String.t()) :: {:ok, any()} | {:error, :not_found}

  defmacro __using__(_opts) do
    quote do
      @behaviour EightDCore.Storage.Store
    end
  end
end

defmodule EightDCore.Storage.MemoryStore do
  @moduledoc """
  In-memory GenServer implementation of the Store protocol for testing MVP.
  """
  use GenServer
  use EightDCore.Storage.Store

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def put(hash, node) do
    GenServer.cast(__MODULE__, {:put, hash, node})
    :ok
  end

  @impl true
  def get(hash) do
    GenServer.call(__MODULE__, {:get, hash})
  end
  
  def all do
    GenServer.call(__MODULE__, :all)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:put, hash, node}, state) do
    {:noreply, Map.put(state, hash, node)}
  end

  @impl true
  def handle_call({:get, hash}, _from, state) do
    case Map.fetch(state, hash) do
      {:ok, val} -> {:reply, {:ok, val}, state}
      :error     -> {:reply, {:error, :not_found}, state}
    end
  end
  
  @impl true
  def handle_call(:all, _from, state) do
    {:reply, state, state}
  end
end
