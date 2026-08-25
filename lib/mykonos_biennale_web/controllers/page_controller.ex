defmodule MykonosBiennaleWeb.PageController do
  use MykonosBiennaleWeb, :controller
  alias MykonosBiennale.Content
  alias MykonosBiennaleWeb.BiennaleController

  alias MykonosBiennale.Repo
  alias MykonosBiennale.Content.{Entity, EntityMedia, Relationship, RelationshipType}

  def home(conn, _params) do
    current_biennale_year =
      Application.get_env(:mykonos_biennale, :current_biennale_year, 2021)

    current_biennale = Content.get_biennale_by_year(current_biennale_year)

    {raw_projects, raw_events, biennales} =
      if current_biennale do
        {
          list_projects_for_biennale(current_biennale),
          list_events_for_biennale(current_biennale),
          Content.list_biennales()
        }
      else
        {[], [], Content.list_biennales()}
      end

    all_entity_ids =
      [current_biennale && current_biennale.id,
       Enum.map(raw_projects, & &1.id),
       Enum.map(raw_events, & &1.id),
       Enum.map(biennales, & &1.id)]
      |> List.flatten()
      |> Enum.reject(&is_nil/1)

    # Single batch query for all media links (includes metadata for role lookup)
    media_links_by_entity = batch_media_links(all_entity_ids)
    media_by_entity = map_media_from_links(media_links_by_entity)

    # Single batch query for event→project relationships
    event_project_map = batch_event_project_ids(Enum.map(raw_events, & &1.id))

    # Single batch query for project→event relationships (for fallback media)
    project_event_ids = batch_project_event_ids(Enum.map(raw_projects, & &1.id))

    # Build project media map (fallback to event media if project has none)
    project_media =
      raw_projects
      |> Enum.map(fn p ->
        media = Map.get(media_by_entity, p.id, [])
        media = if media == [], do: fallback_project_media(p.id, project_event_ids, media_by_entity), else: media
        {p.id, media}
      end)
      |> Enum.into(%{})

    projects = Enum.map(raw_projects, &present_project(&1, media_by_entity, project_event_ids))
    events = Enum.map(raw_events, &present_event(&1, media_by_entity, event_project_map))

    project_event_map =
      events
      |> Enum.filter(& &1[:project_id])
      |> Enum.into(%{}, fn event -> {event.project_id, event.id} end)

    biennale_media = if current_biennale, do: Map.get(media_by_entity, current_biennale.id, []), else: []
    biennale_links = if current_biennale, do: Map.get(media_links_by_entity, current_biennale.id, []), else: []

    statement_bg_media = find_media_by_role(biennale_links, "statement_bg") || List.first(biennale_media)
    program_bg_media = find_media_by_role(biennale_links, "program_bg") || Enum.at(biennale_media, 1)

    biennale_media_map =
      biennales
      |> Enum.map(fn b -> {b.id, Map.get(media_by_entity, b.id, [])} end)
      |> Enum.into(%{})

    conn
    |> assign(:page_title, page_title(current_biennale))
    |> assign(:biennale, current_biennale)
    |> assign(:projects, projects)
    |> assign(:events, events)
    |> assign(:biennales, biennales)
    |> assign(:biennale_media, biennale_media)
    |> assign(:statement_bg_media, statement_bg_media)
    |> assign(:program_bg_media, program_bg_media)
    |> assign(:biennale_media_map, biennale_media_map)
    |> assign(:project_media, project_media)
    |> assign(:project_event_map, project_event_map)
    |> put_view(MykonosBiennaleWeb.BiennaleHTML)
    |> BiennaleController.render_template(current_biennale)
  end

  defp present_project(entity, media_by_entity, project_event_ids) do
    media = Map.get(media_by_entity, entity.id, [])
    media = if media == [], do: fallback_project_media(entity.id, project_event_ids, media_by_entity), else: media

    %{
      id: entity.id,
      title: entity.fields["title"],
      description: entity.fields["description"],
      statement: entity.fields["statement"],
      slug: entity.slug,
      background_image: extract_background(media)
    }
  end

  defp present_event(entity, media_by_entity, event_project_map) do
    media = Map.get(media_by_entity, entity.id, [])

    %{
      id: entity.id,
      title: entity.fields["title"],
      type: entity.fields["type"],
      date: entity.fields["date"],
      time: entity.fields["time"],
      location: entity.fields["location"],
      description: entity.fields["description"],
      slug: entity.slug,
      background_image: extract_background(media),
      project_id: Map.get(event_project_map, entity.id)
    }
  end

  defp extract_background(media) do
    case List.last(media) do
      %{source_type: "upload"} = m ->
        MykonosBiennale.Uploads.media_url(m, size: "card")

      %{source_type: "url", source_url: url} when is_binary(url) ->
        url

      _ ->
        nil
    end
  end

  # -- Batch queries --

  defp batch_media_links(entity_ids) when entity_ids == [], do: %{}

  defp batch_media_links(entity_ids) do
    import Ecto.Query, warn: false

    records =
      Repo.all(
        from em in EntityMedia,
          where: em.entity_id in ^entity_ids,
          order_by: [asc: em.entity_id, asc: em.position],
          preload: [:media]
      )

    Enum.group_by(records, & &1.entity_id)
  end

  defp map_media_from_links(links_by_entity) do
    Map.new(links_by_entity, fn {id, links} -> {id, Enum.map(links, & &1.media)} end)
  end

  defp find_media_by_role(links, role) do
    Enum.find_value(links, fn link ->
      if link.metadata && link.metadata["role"] == role, do: link.media
    end)
  end

  defp batch_event_project_ids(event_ids) when event_ids == [], do: %{}

  defp batch_event_project_ids(event_ids) do
    import Ecto.Query, warn: false

    rt = Repo.get_by(RelationshipType, slug: "event_project")

    if rt do
      Repo.all(
        from r in Relationship,
          where: r.subject_id in ^event_ids and r.relationship_type_id == ^rt.id,
          select: {r.subject_id, r.object_id}
      )
      |> Enum.into(%{})
    else
      %{}
    end
  end

  defp batch_project_event_ids(project_ids) when project_ids == [], do: %{}

  defp batch_project_event_ids(project_ids) do
    import Ecto.Query, warn: false

    rt = Repo.get_by(RelationshipType, slug: "event_project")

    if rt do
      Repo.all(
        from r in Relationship,
          where: r.object_id in ^project_ids and r.relationship_type_id == ^rt.id,
          select: {r.object_id, r.subject_id}
      )
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    else
      %{}
    end
  end

  defp fallback_project_media(project_id, project_event_ids, media_by_entity) do
    event_ids = Map.get(project_event_ids, project_id, [])
    Enum.flat_map(event_ids, fn eid -> Map.get(media_by_entity, eid, []) end)
  end

  # -- Biennale-scoped queries (avoid re-fetching biennale by year) --

  defp list_projects_for_biennale(biennale) do
    import Ecto.Query, warn: false

    be_rt = Repo.get_by(RelationshipType, slug: "biennale_event")
    ep_rt = Repo.get_by(RelationshipType, slug: "event_project")

    if be_rt && ep_rt do
      Repo.all(
        from p in Entity,
          join: ep in Relationship,
          on: ep.relationship_type_id == ^ep_rt.id and ep.object_id == p.id,
          join: be in Relationship,
          on: be.relationship_type_id == ^be_rt.id and be.subject_id == ep.subject_id,
          where: p.type == "project" and be.object_id == ^biennale.id,
          distinct: p.id,
          order_by: [asc: p.identity]
      )
    else
      []
    end
  end

  defp list_events_for_biennale(biennale) do
    import Ecto.Query, warn: false

    rt = Repo.get_by(RelationshipType, slug: "biennale_event")

    if rt do
      Repo.all(
        from e in Entity,
          join: r in Relationship,
          on: r.subject_id == e.id,
          where: e.type == "event" and r.object_id == ^biennale.id and r.relationship_type_id == ^rt.id,
          order_by: [desc: e.inserted_at]
      )
    else
      []
    end
  end

  defp page_title(nil), do: "Mykonos Biennale"
  defp page_title(biennale), do: "Mykonos Biennale #{biennale.fields["year"]}"
end
