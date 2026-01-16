defmodule MykonosBiennaleWeb.Admin.EventLive.FormComponent do
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
        id="event-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <.input field={@form[:title]} type="text" label="Title" required />

          <.input
            field={@form[:type]}
            type="select"
            label="Type"
            prompt="Choose an event type"
            options={[
              {"Exhibition", "exhibition"},
              {"Performance", "performance"},
              {"Video Graffiti", "video_graffiti"},
              {"Dramatic Nights", "dramatic_nights"},
              {"Short Films", "short_films"},
              {"Workshop", "workshop"}
            ]}
            required
          />

          <.input
            field={@form[:biennale_id]}
            type="select"
            label="Biennale"
            prompt="Choose a biennale"
            options={Enum.map(@biennales, &{&1.fields["year"], &1.id})}
            required
          />

          <.input field={@form[:date]} type="date" label="Date" />
          <.input field={@form[:time]} type="time" label="Time" />
          <.input field={@form[:location]} type="text" label="Location" />
          <.input field={@form[:tickets]} type="text" label="Tickets URL" />
          <.input field={@form[:description]} type="textarea" label="Description" rows="5" />
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
            Save Event
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{event: event} = assigns, socket) do
    current_media =
      if event.id do
        Content.list_media_for_entity(event)
      else
        []
      end

    all_media = Content.list_media()
    attached_ids = Enum.map(current_media, & &1.id)
    available_media = Enum.reject(all_media, fn m -> m.id in attached_ids end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:biennales, Content.list_biennales())
     |> assign(:current_media, current_media)
     |> assign(:available_media, available_media)
     |> assign_new(:form, fn ->
       to_form(Content.change_event(event))
     end)}
  end

  @impl true
  def handle_event("validate", %{"event" => event_params}, socket) do
    changeset = Content.change_event(socket.assigns.event, event_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("attach_media", %{"value" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("attach_media", %{"value" => media_id}, socket) do
    event = socket.assigns.event

    if event.id do
      media = Content.get_media!(media_id)

      case Content.attach_media_to_entity(event, media) do
        {:ok, :attached} ->
          current_media = Content.list_media_for_entity(event)
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
      {:noreply, put_flash(socket, :error, "Save the event first before attaching media")}
    end
  end

  def handle_event("detach_media", %{"media-id" => media_id}, socket) do
    event = socket.assigns.event
    media = Content.get_media!(media_id)

    {:ok, :detached} = Content.detach_media_from_entity(event, media)

    current_media = Content.list_media_for_entity(event)
    all_media = Content.list_media()
    attached_ids = Enum.map(current_media, & &1.id)
    available_media = Enum.reject(all_media, fn m -> m.id in attached_ids end)

    {:noreply,
     socket
     |> assign(:current_media, current_media)
     |> assign(:available_media, available_media)
     |> put_flash(:info, "Media detached successfully")}
  end

  def handle_event("save", %{"event" => event_params}, socket) do
    save_event(socket, socket.assigns.action, event_params)
  end

  defp save_event(socket, :edit, event_params) do
    case Content.update_event(socket.assigns.event, event_params) do
      {:ok, event} ->
        notify_parent({:saved, event})

        {:noreply,
         socket
         |> put_flash(:info, "Event updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_event(socket, :new, event_params) do
    case Content.create_event(event_params) do
      {:ok, event} ->
        notify_parent({:saved, event})

        {:noreply,
         socket
         |> put_flash(:info, "Event created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
