defmodule EstimationsWeb.RoomLive do
  # In Phoenix v1.6+ apps, the line below should be: use MyAppWeb, :live_view
  use EstimationsWeb, :live_view

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

  def render(assigns) do
    ~H"""
    <h1 class="text-4xl font-bold">Room: <%= @name %> </h1>
    <%= if @state.name == nil do %>

    <.form let={f} for={:username} phx-submit="save">
    <%= label f, :username %>
    <%= text_input f, :username %>
    <%= error_tag f, :username %>
    <br>
    <%= submit "Save" %>
    </.form>
    <% else %>
    <ul>
      <%= for user <- Map.keys(@room.users) do %>
      <li> <%= user %> :  <%= Map.get(Map.get(@room.users, user), :estimation) %></li>
      <% end %>
    </ul>

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
    </div>
    <% end %>
    """
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
    {:noreply, assign_room(socket |> assign(state: %{name: username}))}
  end

  def handle_info(:update, socket) do
    {:noreply, assign_room(socket)}
  end
end
