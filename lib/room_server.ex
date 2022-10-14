defmodule Estimations.RoomServer do
  use GenServer

  alias Estimations.PubSub

  @timeout 600_000

  @impl true
  def init(_opts) do
    Phoenix.PubSub.subscribe(PubSub, "room:lobby")
    {:ok, %{users: %{}}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @spec subscribe(any) :: :ok | {:error, {:already_registered, pid}}
  def subscribe(room_id), do: Phoenix.PubSub.subscribe(PubSub, "room:#{room_id}")

  @impl true
  def handle_call(:get_room, _from, state) do
    {:reply, state, state, @timeout}
  end

  @impl true
  def handle_cast({:add_user, %{"username" => username}}, state) do
    updated_state = Map.put(state, :users, Map.put(state.users, username, %{estimation: "-"}))
    {:noreply, updated_state}
  end

  @impl true
  def handle_cast({:estimate, params}, state) do
    updated_state =
      Map.put(state, :users, Map.put(state.users, params.username, %{estimation: params.value}))

    {:noreply, updated_state}
  end

  @impl true
  def handle_cast(:clear_estimations, state) do
    updated_state =
      Map.put(
        state,
        :users,
        Map.new(state.users, fn {username, _} -> {username, %{estimation: "-"}} end)
      )

    {:noreply, updated_state}
  end
end
