defmodule MykonosBiennaleWeb.Admin.MediaLive.Index do
  use MykonosBiennaleWeb, :live_view

  alias MykonosBiennale.Content
  alias MykonosBiennale.Content.Media

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :media_collection, Content.list_media())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Media")
    |> assign(:media, Content.get_media!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Media")
    |> assign(:media, %Media{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Media Library")
    |> assign(:media, nil)
  end

  @impl true
  def handle_info({MykonosBiennaleWeb.Admin.MediaLive.FormComponent, {:saved, media}}, socket) do
    {:noreply, stream_insert(socket, :media_collection, media)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    media = Content.get_media!(id)
    {:ok, _} = Content.delete_media(media)

    {:noreply, stream_delete(socket, :media_collection, media)}
  end
end
