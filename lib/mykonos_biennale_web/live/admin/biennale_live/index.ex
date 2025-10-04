defmodule MykonosBiennaleWeb.Admin.BiennaleLive.Index do
  use MykonosBiennaleWeb, :live_view

  alias MykonosBiennale.Content
  alias MykonosBiennale.Content.Biennale

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Manage Biennales")
     |> stream(:biennales, Content.list_biennales())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Biennale")
    |> assign(:biennale, Content.get_biennale!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Biennale")
    |> assign(:biennale, %Biennale{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Manage Biennales")
    |> assign(:biennale, nil)
  end

  @impl true
  def handle_info(
        {MykonosBiennaleWeb.Admin.BiennaleLive.FormComponent, {:saved, biennale}},
        socket
      ) do
    {:noreply, stream_insert(socket, :biennales, biennale)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    biennale = Content.get_biennale!(id)
    {:ok, _} = Content.delete_biennale(biennale)

    {:noreply, stream_delete(socket, :biennales, biennale)}
  end
end
