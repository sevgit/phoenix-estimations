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
    EstimationsWeb.RoomView.render("room.html", assigns)
  end

  def handle_event("estimate", %{"value" => value}, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:estimate, value})
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
