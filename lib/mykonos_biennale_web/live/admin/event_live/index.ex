defmodule MykonosBiennaleWeb.Admin.EventLive.Index do
  use MykonosBiennaleWeb, :live_view

  alias MykonosBiennale.Content

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Manage Events")
     |> stream(:events, Content.list_events())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Event")
    |> assign(:event, Content.get_event!(id))
  end

  defp apply_action(socket, :new, _params) do
    # Create a new entity with type "event" instead of %Event{}
    socket
    |> assign(:page_title, "New Event")
    |> assign(:event, %Content.Entity{type: "event", fields: %{}})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Manage Events")
    |> assign(:event, nil)
  end

  @impl true
  def handle_info(
        {MykonosBiennaleWeb.Admin.EventLive.FormComponent, {:saved, event}},
        socket
      ) do
    {:noreply, stream_insert(socket, :events, event)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    event = Content.get_event!(id)
    {:ok, _} = Content.delete_event(event)

    {:noreply, stream_delete(socket, :events, event)}
  end
end
