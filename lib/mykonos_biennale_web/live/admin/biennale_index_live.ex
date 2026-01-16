defmodule MykonosBiennaleWeb.Admin.BiennaleIndexLive do
  use MykonosBiennaleWeb, :live_view
  alias MykonosBiennale.Content

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :biennales, Content.list_biennales())}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, :biennales, Content.list_biennales())}
  end

  @impl true
  def handle_event("delete", %{"id" => biennale_id}, socket) do
    biennale = Content.get_biennale!(biennale_id)
    {:ok, _} = Content.delete_biennale(biennale)

    {:noreply,
     socket
     |> put_flash(:info, "Biennale deleted successfully!")
     |> assign(:biennales, Content.list_biennales())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-gradient-to-br from-gray-950 via-black to-gray-900">
        <%!-- Admin Header --%>
        <div class="border-b border-gray-800 bg-black/50 backdrop-blur-sm sticky top-0 z-10">
          <div class="max-w-7xl mx-auto px-6 py-4">
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-8">
                <h1 class="text-2xl font-bold uppercase tracking-tight text-white">
                  Admin Biennales
                </h1>

                <nav class="hidden md:flex gap-6">
                  <.link
                    navigate={~p"/admin"}
                    class="text-sm text-gray-400 hover:text-white uppercase tracking-wider transition-colors"
                  >
                    Dashboard
                  </.link>
                  <.link
                    navigate={~p"/admin/biennales"}
                    class="text-sm text-gray-400 hover:text-white uppercase tracking-wider transition-colors"
                  >
                    Biennales
                  </.link>
                  <.link
                    navigate={~p"/admin/events"}
                    class="text-sm text-gray-400 hover:text-white uppercase tracking-wider transition-colors"
                  >
                    Events
                  </.link>
                </nav>
              </div>

              <div class="flex items-center gap-4">
                <.link
                  navigate={~p"/"}
                  class="text-sm text-gray-400 hover:text-white uppercase tracking-wider transition-colors"
                >
                  View Site
                </.link>
                <div class="h-6 w-px bg-gray-700"></div>
                <span class="text-sm text-gray-500">{@current_scope.user.email}</span>
              </div>
            </div>
          </div>
        </div>

        <%!-- Main Content --%>
        <div class="max-w-7xl mx-auto px-6 py-12">
          <div class="flex items-center justify-between mb-8">
            <h2 class="text-xl font-bold uppercase text-gray-300">Biennale Editions</h2>
            <.link
              navigate={~p"/admin/biennales/new"}
              class="inline-flex items-center gap-2 px-6 py-3 bg-purple-600 hover:bg-purple-700 text-white font-bold uppercase tracking-wider rounded-lg transition-colors"
            >
              <.icon name="hero-plus-solid" class="size-5" /> New Biennale
            </.link>
          </div>

          <%= if @biennales == [] do %>
            <div class="text-center py-12 border border-gray-800 rounded-lg">
              <p class="text-gray-500 mb-4">No biennales created yet.</p>
              <.link
                navigate={~p"/admin/biennales/new"}
                class="inline-block px-6 py-3 bg-purple-600 hover:bg-purple-700 text-white font-bold uppercase tracking-wider rounded-lg transition-colors"
              >
                Create First Biennale
              </.link>
            </div>
          <% else %>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <%= for biennale <- @biennales do %>
                <div class="bg-gray-900/50 border border-gray-800 rounded-lg p-6">
                  <div class="flex items-start justify-between mb-4">
                    <div>
                      <.link
                        navigate={~p"/admin/biennales/#{biennale.id}"}
                        class="text-xl font-bold text-white hover:text-purple-400 transition-colors"
                      >
                        {biennale.fields["year"]} - {biennale.fields["theme"]}
                      </.link>
                      <%= if biennale.fields["start_date"] && biennale.fields["end_date"] do %>
                        <p class="text-sm text-gray-500 mt-1">
                          {Calendar.strftime(biennale.fields["start_date"], "%B %d")} – {Calendar.strftime(
                            biennale.fields["end_date"],
                            "%B %d, %Y"
                          )}
                        </p>
                      <% end %>
                    </div>
                    <div class="flex gap-2">
                      <.link
                        navigate={~p"/admin/biennales/#{biennale.id}/edit"}
                        class="p-2 hover:bg-gray-800 rounded transition-colors"
                      >
                        <.icon name="hero-pencil" class="size-4 text-gray-400 hover:text-white" />
                      </.link>
                      <button
                        phx-click={JS.push("delete", value: %{id: biennale.id})}
                        phx-confirm="Are you sure you want to delete this biennale?"
                        class="p-2 hover:bg-gray-800 rounded transition-colors"
                      >
                        <.icon name="hero-trash" class="size-4 text-red-400 hover:text-red-300" />
                      </button>
                    </div>
                  </div>
                  <p class="text-gray-400 text-sm">
                    {String.truncate(biennale.fields["description"] || "", 150)}
                  </p>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
