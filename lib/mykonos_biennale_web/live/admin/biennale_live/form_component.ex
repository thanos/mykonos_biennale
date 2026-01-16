defmodule MykonosBiennaleWeb.Admin.BiennaleLive.FormComponent do
  use MykonosBiennaleWeb, :live_component

  alias MykonosBiennale.Content

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.form
        for={@form}
        id="biennale-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <.input field={@form[:year]} type="number" label="Year" required />
          <.input field={@form[:theme]} type="text" label="Theme" required />
          <.input field={@form[:statement]} type="textarea" label="Statement" rows="3" />
          <.input field={@form[:description]} type="textarea" label="Description" rows="5" />
          <.input field={@form[:start_date]} type="date" label="Start Date" />
          <.input field={@form[:end_date]} type="date" label="End Date" />
        </div>

        <div class="mt-6">
          <label class="block text-sm font-semibold text-gray-900 dark:text-gray-100 mb-2">
            Attached Media
          </label>

          <%= if @current_media == [] do %>
            <p class="text-sm text-gray-500 dark:text-gray-400 mb-4">
              No media attached yet
            </p>
          <% else %>
            <div class="grid grid-cols-2 sm:grid-cols-3 gap-4 mb-4">
              <div
                :for={media <- @current_media}
                class="relative group bg-gray-50 dark:bg-gray-800 rounded-lg overflow-hidden"
              >
                <div class="aspect-video bg-gray-100 dark:bg-gray-700 flex items-center justify-center">
                  <%= case media.source_type do %>
                    <% "upload" -> %>
                      <%= if media.source_path do %>
                        <img
                          src={"/uploads/#{media.source_path}"}
                          alt={media.alt_text || media.caption}
                          class="w-full h-full object-cover"
                        />
                      <% else %>
                        <.icon name="hero-photo" class="w-8 h-8 text-gray-400" />
                      <% end %>
                    <% "url" -> %>
                      <%= if media.source_url do %>
                        <img
                          src={media.source_url}
                          alt={media.alt_text || media.caption}
                          class="w-full h-full object-cover"
                        />
                      <% else %>
                        <.icon name="hero-link" class="w-8 h-8 text-gray-400" />
                      <% end %>
                    <% "embed" -> %>
                      <.icon name="hero-video-camera" class="w-8 h-8 text-gray-400" />
                  <% end %>
                </div>
                <button
                  type="button"
                  phx-click="detach_media"
                  phx-value-media-id={media.id}
                  phx-target={@myself}
                  class="absolute top-2 right-2 bg-red-600 text-white p-1 rounded opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <.icon name="hero-x-mark" class="w-4 h-4" />
                </button>
                <%= if media.caption do %>
                  <p class="px-2 py-1 text-xs text-gray-600 dark:text-gray-300 truncate">
                    {media.caption}
                  </p>
                <% end %>
              </div>
            </div>
          <% end %>

          <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
              Add Media
            </label>
            <select
              phx-change="attach_media"
              phx-target={@myself}
              class="w-full rounded-lg border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
            >
              <option value="">Select media to attach...</option>
              <%= for media <- @available_media do %>
                <option value={media.id}>
                  {media.caption || "#{media.source_type} - #{media.id}"}
                </option>
              <% end %>
            </select>
          </div>
        </div>

        <div class="mt-6 flex items-center justify-end gap-x-6">
          <.link patch={@patch} class="text-sm font-semibold text-gray-400 hover:text-white">
            Cancel
          </.link>
          <button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
            Save Biennale
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{biennale: biennale} = assigns, socket) do
    current_media =
      if biennale.id do
        Content.list_media_for_entity(biennale)
      else
        []
      end

    all_media = Content.list_media()
    attached_ids = Enum.map(current_media, & &1.id)
    available_media = Enum.reject(all_media, fn m -> m.id in attached_ids end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:current_media, current_media)
     |> assign(:available_media, available_media)
     |> assign_new(:form, fn ->
       to_form(Content.change_biennale(biennale))
     end)}
  end

  @impl true
  def handle_event("validate", %{"biennale" => biennale_params}, socket) do
    changeset = Content.change_biennale(socket.assigns.biennale, biennale_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("attach_media", %{"value" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("attach_media", %{"value" => media_id}, socket) do
    biennale = socket.assigns.biennale

    if biennale.id do
      media = Content.get_media!(media_id)

      case Content.attach_media_to_entity(biennale, media) do
        {:ok, :attached} ->
          current_media = Content.list_media_for_entity(biennale)
          all_media = Content.list_media()
          attached_ids = Enum.map(current_media, & &1.id)
          available_media = Enum.reject(all_media, fn m -> m.id in attached_ids end)

          {:noreply,
           socket
           |> assign(:current_media, current_media)
           |> assign(:available_media, available_media)
           |> put_flash(:info, "Media attached successfully")}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, reason)}
      end
    else
      {:noreply, put_flash(socket, :error, "Save the biennale first before attaching media")}
    end
  end

  def handle_event("detach_media", %{"media-id" => media_id}, socket) do
    biennale = socket.assigns.biennale
    media = Content.get_media!(media_id)

    {:ok, :detached} = Content.detach_media_from_entity(biennale, media)

    current_media = Content.list_media_for_entity(biennale)
    all_media = Content.list_media()
    attached_ids = Enum.map(current_media, & &1.id)
    available_media = Enum.reject(all_media, fn m -> m.id in attached_ids end)

    {:noreply,
     socket
     |> assign(:current_media, current_media)
     |> assign(:available_media, available_media)
     |> put_flash(:info, "Media detached successfully")}
  end
  end

  def handle_event("save", %{"biennale" => biennale_params}, socket) do
    save_biennale(socket, socket.assigns.action, biennale_params)
  end

  defp save_biennale(socket, :edit, biennale_params) do
    case Content.update_biennale(socket.assigns.biennale, biennale_params) do
      {:ok, biennale} ->
        notify_parent({:saved, biennale})

        {:noreply,
         socket
         |> put_flash(:info, "Biennale updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_biennale(socket, :new, biennale_params) do
    case Content.create_biennale(biennale_params) do
      {:ok, biennale} ->
        notify_parent({:saved, biennale})

        {:noreply,
         socket
         |> put_flash(:info, "Biennale created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
