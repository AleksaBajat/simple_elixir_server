defmodule KvStorage do
  require Logger
  use GenServer

    def child_spec(opts) do
      %{
        id: KvStorage,
        start: {__MODULE__, :start_link, [opts]},
        shutdown: 5_000,
        restart: :permanent,
        type: :worker
       }
    end

  def start_link(init_value \\ %{}) do
    Logger.info("KV STORAGE STARTED")
    Logger.info("MODULE NAME: #{__MODULE__}")
    GenServer.start_link(__MODULE__, init_value, name: __MODULE__)
  end

  def init(init_arg) do
    Logger.info("KV STORAGE INIT")
    {:ok, init_arg}
  end

  def handle_call({:get, key}, _from, state) do
    Logger.info("KV STORAGE HANDLE CALL")
    {:reply, Map.get(state, key), state}
  end

  def handle_cast({:put, key, value}, state) do
    Logger.info("KV STORAGE HANDLE CAST")
    {:noreply, Map.put(state, key, value)}
  end

  def get(key) do
    Logger.info("KV STORAGE HANDLE GET")
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, value) do
    Logger.info("KV STORAGE HANDLE PUT")
    GenServer.cast(__MODULE__, {:put, key, value})
  end

end
