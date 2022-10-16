defmodule Estimations.RoomServer do
  use GenServer
  alias Estimations.PubSub

  @timeout 600_000

  @impl true
  def init(_opts) do
    {:ok, %{users: %{}, name: nil}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

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

  @impl true
  def handle_cast({:subscribe, room_name}, state) do
    Phoenix.PubSub.subscribe(PubSub, "presence:#{room_name}")
    {:noreply, state}
  end

  @impl true
  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, state) do
    {:noreply, state |> handle_leaves(diff.leaves)}
  end

  defp handle_leaves(state, leaves) do
    Enum.reduce(leaves, state, fn {username, meta}, state ->
      room_name = meta |> Map.get(:metas) |> List.first() |> Map.get(:room_name)
      remove_user(state, username, room_name)
    end)
  end

  defp remove_user(state, username, room_name) do
    # TODO: Review if this is a potential race condition
    # TODO: Move broadcast to a separate function and call it from whoever is calling this function
    updated_state = Map.put(state, :users, Map.delete(state.users, username))
    :ok = Phoenix.PubSub.broadcast(Estimations.PubSub, room_name, :update)
    updated_state
  end
end
