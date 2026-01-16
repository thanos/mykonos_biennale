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
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:biennales, Content.list_biennales())
     |> assign_new(:form, fn ->
       to_form(Content.change_event(event))
     end)}
  end

  @impl true
  def handle_event("validate", %{"event" => event_params}, socket) do
    changeset = Content.change_event(socket.assigns.event, event_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
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
