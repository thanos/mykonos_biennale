defmodule MykonosBiennaleWeb.Admin.BiennaleLive.FormComponent do
  use MykonosBiennaleWeb, :live_component

  alias MykonosBiennale.Content
  alias MykonosBiennaleWeb.BiennaleHTML
  alias Ecto.Changeset

  defmodule BiennaleForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :year, :integer
      field :theme, :string
      field :statement, :string
      field :description, :string
      field :start_date, :date
      field :end_date, :date
      field :visible, :boolean, default: true
      field :template, :string, default: "default"
      field :show_program, :boolean, default: true
    end

    def changeset(%__MODULE__{} = form, attrs) when is_map(attrs) do
      form
      |> cast(attrs, [
        :year,
        :theme,
        :statement,
        :description,
        :start_date,
        :end_date,
        :visible,
        :template,
        :show_program
      ])
      |> validate_required([:year, :theme])
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-theme="light" class="bg-white rounded-xl [&_.label]:text-gray-900 [&_h1]:text-gray-900">
      <.header>
        {@title}
      </.header>

      <.form
        for={@form}
        id="biennale-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        novalidate
      >
        <div class="space-y-4">
          <.input field={@form[:year]} type="number" label="Year" required />
          <.input field={@form[:theme]} type="text" label="Theme" required />
          <.input
            field={@form[:template]}
            type="select"
            label="Template"
            options={BiennaleHTML.template_options()}
          />
          <.input field={@form[:statement]} type="textarea" label="Statement" rows="3" />
          <.input field={@form[:description]} type="textarea" label="Description" rows="5" />
          <.input field={@form[:start_date]} type="date" label="Start Date" />
          <.input field={@form[:end_date]} type="date" label="End Date" />
          <.input field={@form[:show_program]} type="checkbox" label="Show program" />
        </div>

        <hr class="my-6 border-gray-200" />

        <h3 class="text-sm font-semibold text-gray-900 mb-3">Background Images</h3>

        <div class="space-y-6">
          <.image_upload
            label="Statement Background"
            image={@statement_bg}
            upload={@uploads.statement_bg}
            myself={@myself}
          />

          <.image_upload
            label="Program Background"
            image={@program_bg}
            upload={@uploads.program_bg}
            myself={@myself}
          />
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

  defp image_upload(assigns) do
    ~H"""
    <div class="space-y-2">
      <label class="block text-sm font-semibold text-gray-900">{@label}</label>
      <%= if @image do %>
        <div class="relative group inline-block">
          <img
            src={MykonosBiennale.Uploads.media_url(@image, size: "card")}
            alt={@label}
            class="w-full max-w-md h-32 object-cover rounded-lg border border-gray-300"
          />
          <button
            type="button"
            phx-click="remove_bg"
            phx-value-role={if @label == "Statement Background", do: "statement_bg", else: "program_bg"}
            phx-target={@myself}
            class="absolute top-2 right-2 bg-red-600 text-white p-1 rounded opacity-0 group-hover:opacity-100 transition-opacity"
          >
            <.icon name="hero-x-mark" class="w-4 h-4" />
          </button>
        </div>
      <% else %>
        <div
          class="border-2 border-dashed border-gray-300 rounded-lg p-4 text-center hover:border-blue-500 transition-colors"
          phx-drop-target={@upload.ref}
        >
          <.live_file_input upload={@upload} class="hidden" />
          <button
            type="button"
            phx-click={JS.dispatch("click", to: "##{@upload.ref}")}
            class="text-blue-600 hover:text-blue-700 font-medium text-sm"
          >
            Click to upload or drag and drop
          </button>
          <p class="mt-1 text-xs text-gray-500">JPG, PNG, WEBP up to 10MB</p>
        </div>
      <% end %>

      <%= for entry <- @upload.entries do %>
        <div class="flex items-center justify-between bg-gray-50 p-2 rounded">
          <div class="flex items-center gap-2">
            <.icon name="hero-document" class="w-4 h-4 text-gray-400" />
            <span class="text-sm text-gray-900">{entry.client_name}</span>
            <span class="text-xs text-gray-500">{format_bytes(entry.client_size)}</span>
          </div>
          <button
            type="button"
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            phx-target={@myself}
            class="text-red-600 hover:text-red-700"
          >
            <.icon name="hero-x-mark" class="w-4 h-4" />
          </button>
        </div>
      <% end %>

      <%= for err <- upload_errors(@upload) do %>
        <p class="text-sm text-red-600">{error_to_string(err)}</p>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(%{biennale: biennale} = assigns, socket) do
    media_links =
      if biennale.id do
        Content.list_entity_media_links_for_entity(biennale)
      else
        []
      end

    statement_bg = find_media_by_role(media_links, "statement_bg")
    program_bg = find_media_by_role(media_links, "program_bg")

    {:ok,
      socket
      |> assign(assigns)
      |> assign(:statement_bg, statement_bg)
      |> assign(:program_bg, program_bg)
      |> assign_new(:form, fn ->
        changeset = BiennaleForm.changeset(%BiennaleForm{}, biennale_form_attrs(biennale))
        to_form(changeset, as: :biennale)
      end)
      |> allow_upload(:statement_bg,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: 10_000_000
      )
      |> allow_upload(:program_bg,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: 10_000_000
      )}
  end

  @impl true
  def handle_event("validate", params, socket) do
    biennale_params = extract_biennale_params(params)

    changeset =
      socket.assigns.form.source.data
      |> BiennaleForm.changeset(biennale_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: :biennale))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :statement_bg, ref)}
  end

  def handle_event("remove_bg", %{"role" => role}, socket) do
    biennale = socket.assigns.biennale

    if biennale.id do
      media = if role == "statement_bg", do: socket.assigns.statement_bg, else: socket.assigns.program_bg

      if media do
        Content.detach_media_from_entity(biennale, media)
      end

      media_links = Content.list_entity_media_links_for_entity(biennale)
      statement_bg = find_media_by_role(media_links, "statement_bg")
      program_bg = find_media_by_role(media_links, "program_bg")

      {:noreply,
       socket
       |> assign(:statement_bg, statement_bg)
       |> assign(:program_bg, program_bg)
       |> put_flash(:info, "Background removed")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("save", params, socket) do
    biennale_params = extract_biennale_params(params)
    save_biennale(socket, socket.assigns.action, biennale_params)
  end

  defp save_biennale(socket, :edit, biennale_params) do
    changeset = BiennaleForm.changeset(socket.assigns.form.source.data, biennale_params)

    if changeset.valid? do
      attrs = biennale_attrs_from_form(changeset)

      case Content.update_biennale(socket.assigns.biennale, attrs) do
        {:ok, biennale} ->
          process_uploads(socket, biennale)
          notify_parent({:saved, biennale})

          {:noreply,
           socket
           |> put_flash(:info, "Biennale updated successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = entity_changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Could not update biennale")
           |> assign(
             :form,
             to_form(Changeset.add_error(changeset, :base, "Save failed"), as: :biennale)
           )
           |> assign(:entity_changeset, entity_changeset)}
      end
    else
      {:noreply, assign(socket, form: to_form(%{changeset | action: :validate}, as: :biennale))}
    end
  end

  defp save_biennale(socket, :new, biennale_params) do
    changeset = BiennaleForm.changeset(socket.assigns.form.source.data, biennale_params)

    if changeset.valid? do
      attrs = biennale_attrs_from_form(changeset)

      case Content.create_biennale(attrs) do
        {:ok, biennale} ->
          process_uploads(socket, biennale)
          notify_parent({:saved, biennale})

          {:noreply,
           socket
           |> put_flash(:info, "Biennale created successfully")
           |> push_patch(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = entity_changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Could not create biennale")
           |> assign(
             :form,
             to_form(Changeset.add_error(changeset, :base, "Save failed"), as: :biennale)
           )
           |> assign(:entity_changeset, entity_changeset)}
      end
    else
      {:noreply, assign(socket, form: to_form(%{changeset | action: :validate}, as: :biennale))}
    end
  end

  defp process_uploads(socket, biennale) do
    consume_bg_upload(socket, biennale, :statement_bg, "statement_bg")
    consume_bg_upload(socket, biennale, :program_bg, "program_bg")
  end

  defp consume_bg_upload(socket, biennale, upload_key, role) do
    uploaded_files =
      consume_uploaded_entries(socket, upload_key, fn %{path: path}, entry ->
        ext = Path.extname(entry.client_name)
        filename = "#{Ecto.UUID.generate()}#{ext}"
        dest = MykonosBiennale.Uploads.uploads_path(filename)
        MykonosBiennale.Uploads.ensure_uploads_dir()
        File.cp!(path, dest)
        {:ok, %{path: filename, mime_type: entry.client_type, original_name: entry.client_name}}
      end)

    for %{path: path, mime_type: mime_type, original_name: original_name} <- uploaded_files do
      {:ok, media} =
        Content.create_media(%{
          caption: "#{role} - #{biennale.identity}",
          source_type: "upload",
          source_path: path,
          mime_type: mime_type,
          original_name: original_name
        })

      Content.attach_media_to_entity(biennale, media, metadata: %{"role" => role})
    end
  end

  defp find_media_by_role(media_links, role) do
    Enum.find_value(media_links, fn link ->
      if link.metadata && link.metadata["role"] == role, do: link.media
    end)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp extract_biennale_params(%{"biennale" => p}) when is_map(p), do: p
  defp extract_biennale_params(%{"entity" => p}) when is_map(p), do: p
  defp extract_biennale_params(_), do: %{}

  defp biennale_form_attrs(%Content.Entity{fields: fields} = entity) when is_map(fields) do
    %{
      year: map_get_int(fields, "year"),
      theme: Map.get(fields, "theme"),
      statement: Map.get(fields, "statement"),
      description: Map.get(fields, "description"),
      start_date: map_get_date(fields, "start_date"),
      end_date: map_get_date(fields, "end_date"),
      visible: true,
      template: entity.template || "default",
      show_program: Map.get(fields, "show_program", true)
    }
  end

  defp biennale_form_attrs(%Content.Entity{}), do: %{visible: true, show_program: true}

  defp map_get_int(map, key) do
    case Map.get(map, key) do
      i when is_integer(i) ->
        i

      s when is_binary(s) ->
        case Integer.parse(s) do
          {i, _} -> i
          :error -> nil
        end

      _ ->
        nil
    end
  end

  defp map_get_date(map, key) do
    case Map.get(map, key) do
      %Date{} = d ->
        d

      s when is_binary(s) ->
        case Date.from_iso8601(s) do
          {:ok, d} -> d
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp biennale_attrs_from_form(%Changeset{} = changeset) do
    form = Changeset.apply_changes(changeset)

    %{
      year: form.year,
      theme: form.theme,
      statement: form.statement,
      description: form.description,
      start_date: form.start_date,
      end_date: form.end_date,
      visible: form.visible,
      template: form.template,
      show_program: form.show_program
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  defp format_bytes(bytes) do
    cond do
      bytes >= 1_000_000 -> "#{Float.round(bytes / 1_000_000, 1)} MB"
      bytes >= 1_000 -> "#{Float.round(bytes / 1_000, 1)} KB"
      true -> "#{bytes} B"
    end
  end

  defp error_to_string(:too_large), do: "File is too large (max 10MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted"
  defp error_to_string(err), do: "Upload error: #{inspect(err)}"
end
