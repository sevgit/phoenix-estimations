defmodule EstimationsWeb.RoomLive do
  # In Phoenix v1.6+ apps, the line below should be: use MyAppWeb, :live_view
  use EstimationsWeb, :live_view

  def render(assigns) do
    ~H"""
    Current temperature: <%= @temperature %>
    <button phx-click="increase-temp">inc</button>
    """
  end

  @spec mount(any, map, map) :: {:ok, map}
  def mount(_params, %{}, socket) do
    temperature = 10
    {:ok, assign(socket, :temperature, temperature)}
  end

  def handle_event("increase-temp", _params, socket) do
    temperature = socket.assigns.temperature + 1
    {:noreply, assign(socket, :temperature, temperature)}
  end
end
