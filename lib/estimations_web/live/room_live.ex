defmodule EstimationsWeb.RoomLive do
  # In Phoenix v1.6+ apps, the line below should be: use MyAppWeb, :live_view
  use EstimationsWeb, :live_view
  alias EstimationsWeb.Presence

  @impl true
  def handle_params(%{"name" => name} = _params, _uri, socket) do
    :ok = Phoenix.PubSub.subscribe(Estimations.PubSub, name)
    {:noreply, assign_room(socket, name)}
  end

  def handle_params(_params, _uri, socket) do
    new_room_name =
      ?a..?z
      |> Enum.take_random(6)
      |> List.to_string()

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        Estimations.RoomSupervisor,
        {Estimations.RoomServer, name: via_tuple(new_room_name)}
      )

    GenServer.cast(via_tuple(new_room_name), {:subscribe, new_room_name})

    {:noreply,
     push_redirect(
       socket,
       to:
         EstimationsWeb.Router.Helpers.live_path(socket, EstimationsWeb.RoomLive,
           name: new_room_name
         )
     )}
  end

  defp via_tuple(name) do
    {:via, Registry, {Estimations.RoomRegistry, name}}
  end

  defp assign_room(socket, name) do
    socket
    |> assign(name: name)
    |> assign_room()
  end

  defp assign_room(%{assigns: %{name: name, state: state}} = socket) do
    room = GenServer.call(via_tuple(name), :get_room)
    assign(socket, room: room, state: state)
  end

  defp assign_room(%{assigns: %{name: name}} = socket) do
    room = GenServer.call(via_tuple(name), :get_room)
    assign(socket, room: room, state: %{name: nil})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="container m-auto grid place-items-center flex-wrap">
      <h1 class="text-4xl font-bold text-white mb-5 mt-10">Room: <%= @name %> </h1>
      <%= if @state.name == nil do %>

      <.form let={f} for={:username} phx-submit="save" class="bg-white shadow-lg hover:shadow-xl rounded px-8 pt-6 pb-8 mb-4 grid gap-3">
        <h2 class="text-2xl ">Choose a name:</h2>
        <%= text_input f, :username, class: "shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline", placeholder: "Username" %>
        <button type="submit" class="bg-participant-gradient py-2 px-5 rounded-sm font-bold">Save</button>
      </.form>
      <% else %>
      <section class="flex gap-2 p-5">
        <%= for user <- Map.keys(@room.users) do %>
        <div class="grid place-items-center px-3 py-2 rounded-sm animate-ping-once bg-participant-gradient shadow-md">
          <span class="border-b-2 pb-1 min-w-50px"><%= user %></span>
          <span class="text-2xl font-bold"><%= Map.get(Map.get(@room.users, user), :estimation) %></span>
        </div>
        <% end %>
      </section>

      <div>
        <button phx-click="estimate" value="0.5" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">0.5</button>
        <button phx-click="estimate" value="1" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">1</button>
        <button phx-click="estimate" value="2" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">2</button>
        <button phx-click="estimate" value="3" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">3</button>
        <button phx-click="estimate" value="5" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">5</button>
        <button phx-click="estimate" value="8" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">8</button>
        <button phx-click="estimate" value="13" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">13</button>
        <button phx-click="estimate" value="20" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">20</button>
        <button phx-click="estimate" value="?" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">?</button>
        <button phx-click="clear_estimations" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">?</button>
      </div>
      <% end %>
    </section>
    """
  end

  @impl true
  def handle_event("clear_estimations", %{}, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), :clear_estimations)
    :ok = Phoenix.PubSub.broadcast(Estimations.PubSub, name, :update)
    {:noreply, assign_room(socket, name)}
  end

  def handle_event(
        "estimate",
        %{"value" => value},
        %{assigns: %{name: name, state: %{name: %{"username" => username}}}} = socket
      ) do
    :ok = GenServer.cast(via_tuple(name), {:estimate, %{value: value, username: username}})
    :ok = Phoenix.PubSub.broadcast(Estimations.PubSub, name, :update)
    {:noreply, assign_room(socket)}
  end

  def handle_event("save", %{"username" => username}, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:add_user, username})
    :ok = Phoenix.PubSub.broadcast(Estimations.PubSub, name, :update)

    {:ok, _} =
      Presence.track(self(), "presence:#{name}", username["username"], %{
        joined_at: :os.system_time(:seconds),
        room_name: name
      })

    {:noreply, assign_room(socket |> assign(state: %{name: username}))}
  end

  @impl true
  def handle_info(:update, socket) do
    {:noreply, assign_room(socket)}
  end
end
