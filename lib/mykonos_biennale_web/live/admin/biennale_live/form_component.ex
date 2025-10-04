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

        <div class="mt-6 flex items-center justify-end gap-x-6">
          <.link patch={@patch} class="text-sm font-semibold text-gray-400 hover:text-white">
            Cancel
          </.link>
          <button
            type="submit"
            phx-disable-with="Saving..."
            class="btn btn-primary"
          >
            Save Biennale
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{biennale: biennale} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Content.change_biennale(biennale))
     end)}
  end

  @impl true
  def handle_event("validate", %{"biennale" => biennale_params}, socket) do
    changeset = Content.change_biennale(socket.assigns.biennale, biennale_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
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
