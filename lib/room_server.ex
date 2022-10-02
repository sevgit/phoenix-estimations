defmodule Estimations.RoomServer do
  use GenServer

  alias Estimations.PubSub

  @timeout 600_000

  @impl true
  def init(_opts) do
    Phoenix.PubSub.subscribe(PubSub, "room:lobby")
    {:ok, %{"test_room" => 0}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def subscribe(room_id), do: Phoenix.PubSub.subscribe(PubSub, "room:#{room_id}")

  @impl true
  def handle_call(:get_room, _from, state) do
    {:reply, state, state, @timeout}
  end
end
