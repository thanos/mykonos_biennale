defmodule MykonosBiennaleWeb.PageController do
  use MykonosBiennaleWeb, :controller
  alias MykonosBiennale.Content
  alias MykonosBiennaleWeb.BiennaleController

  alias MykonosBiennale.Repo
  alias MykonosBiennale.Content.{Entity, EntityMedia, Relationship, RelationshipType}

  @team_role_labels %{
    "curator" => "Curator",
    "producer" => "Producer",
    "director" => "Director",
    "coordinator" => "Coordinator",
    "designer" => "Designer",
    "technical" => "Technical",
    "volunteer" => "Volunteer"
  }

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
    rt = preload_relationship_types()
    event_project_map = batch_event_project_ids(Enum.map(raw_events, & &1.id), rt)

    # Single batch query for project→event relationships (for fallback media)
    project_event_ids = batch_project_event_ids(Enum.map(raw_projects, & &1.id), rt)

    # Single batch query for project participants (scoped to this biennale's events)
    biennale_event_ids = Enum.map(raw_events, & &1.id)
    project_participants = batch_project_participants(Enum.map(raw_projects, & &1.id), rt, biennale_event_ids)
    project_directors = batch_project_directors(Enum.map(raw_projects, & &1.id), rt, biennale_event_ids)

    # Single batch query for event participants
    event_participants = batch_event_participants(Enum.map(raw_events, & &1.id), rt)

    # Build project media map (fallback to event media if project has none)
    project_media =
      raw_projects
      |> Enum.map(fn p ->
        media = Map.get(media_by_entity, p.id, [])
        media = if media == [], do: fallback_project_media(p.id, project_event_ids, media_by_entity), else: media
        {p.id, media}
      end)
      |> Enum.into(%{})

    projects = Enum.map(raw_projects, &present_project(&1, media_by_entity, project_event_ids, project_participants, project_directors))
    events = Enum.map(raw_events, &present_event(&1, media_by_entity, event_project_map, event_participants))

    project_event_map =
      events
      |> Enum.filter(& &1[:project_id])
      |> Enum.into(%{}, fn event -> {event.project_id, event.id} end)

    biennale_media = if current_biennale, do: Map.get(media_by_entity, current_biennale.id, []), else: []
    biennale_links = if current_biennale, do: Map.get(media_links_by_entity, current_biennale.id, []), else: []

    statement_bg_media = find_media_by_role(biennale_links, "statement_bg") || List.first(biennale_media)
    program_bg_media = find_media_by_role(biennale_links, "program_bg") || Enum.at(biennale_media, 1)
    team_members = load_team_members(current_biennale, rt)
    sponsors = load_sponsors(biennale_links)

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
    |> assign(:team_members, team_members)
    |> assign(:sponsors, sponsors)
    |> put_view(MykonosBiennaleWeb.BiennaleHTML)
    |> BiennaleController.render_template(current_biennale)
  end

  defp present_project(entity, media_by_entity, project_event_ids, project_participants, project_directors) do
    media = Map.get(media_by_entity, entity.id, [])
    media = if media == [], do: fallback_project_media(entity.id, project_event_ids, media_by_entity), else: media

    %{
      id: entity.id,
      title: entity.fields["title"],
      description: entity.fields["description"],
      statement: entity.fields["statement"],
      slug: entity.slug,
      background_image: extract_background(media),
      participants: Map.get(project_participants, entity.id, []),
      directors: Map.get(project_directors, entity.id, [])
    }
  end

  defp present_event(entity, media_by_entity, event_project_map, event_participants) do
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
      project_id: Map.get(event_project_map, entity.id),
      participants: Map.get(event_participants, entity.id, [])
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

  defp preload_relationship_types do
    import Ecto.Query, warn: false
    slugs = ["biennale_event", "event_project", "artwork_event", "artwork_participant", "directed", "screened_at", "biennale_team"]
    _ = slugs
    Repo.all(from rt in RelationshipType, where: rt.slug in ^slugs)
    |> Enum.into(%{}, fn rt -> {rt.slug, rt} end)
  end

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

  defp load_team_members(nil, _rt), do: []

  defp load_team_members(biennale, rt) do
    import Ecto.Query, warn: false
    bt_rt = Map.get(rt, "biennale_team")

    if bt_rt do
      rels =
        Repo.all(
          from r in Relationship,
            where: r.subject_id == ^biennale.id and r.relationship_type_id == ^bt_rt.id,
            preload: [:object]
        )

      participant_ids = Enum.map(rels, & &1.object_id)

      headshots = batch_headshots(participant_ids)

      Enum.map(rels, fn rel ->
        participant = rel.object
        role = rel.fields && rel.fields["role"]

        %{
          id: participant.id,
          name: participant.identity,
          role: role,
          role_label: Map.get(@team_role_labels, role, role),
          photo: Map.get(headshots, participant.id)
        }
      end)
    else
      []
    end
  end

  defp batch_headshots(participant_ids) when participant_ids == [], do: %{}

  defp batch_headshots(participant_ids) do
    import Ecto.Query, warn: false

    links =
      Repo.all(
        from em in EntityMedia,
          where:
            em.entity_id in ^participant_ids and
              fragment("? ->> 'role'", em.metadata) == "headshot",
          preload: [:media]
      )

    Map.new(links, fn link -> {link.entity_id, link.media} end)
  end

  defp load_sponsors(links) do
    Enum.filter(links, fn link -> link.metadata && link.metadata["role"] == "sponsor" end)
    |> Enum.map(fn link ->
      %{
        media_id: link.media_id,
        media: link.media,
        name: link.metadata["name"] || link.media.caption || "",
        url: link.metadata["url"] || ""
      }
    end)
  end

  defp batch_event_project_ids(event_ids, _rt) when event_ids == [], do: %{}

  defp batch_event_project_ids(event_ids, rt) do
    import Ecto.Query, warn: false

    ep_rt = Map.get(rt, "event_project")

    if ep_rt do
      Repo.all(
        from r in Relationship,
          where: r.subject_id in ^event_ids and r.relationship_type_id == ^ep_rt.id,
          select: {r.subject_id, r.object_id}
      )
      |> Enum.into(%{})
    else
      %{}
    end
  end

  defp batch_project_event_ids(project_ids, _rt) when project_ids == [], do: %{}

  defp batch_project_event_ids(project_ids, rt) do
    import Ecto.Query, warn: false

    ep_rt = Map.get(rt, "event_project")

    if ep_rt do
      Repo.all(
        from r in Relationship,
          where: r.object_id in ^project_ids and r.relationship_type_id == ^ep_rt.id,
          select: {r.object_id, r.subject_id}
      )
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    else
      %{}
    end
  end

  defp batch_project_participants(project_ids, _rt, _biennale_event_ids) when project_ids == [], do: %{}

  defp batch_project_participants(project_ids, rt, biennale_event_ids) do
    import Ecto.Query, warn: false

    ap_rt = Map.get(rt, "artwork_participant")
    ae_rt = Map.get(rt, "artwork_event")
    ep_rt = Map.get(rt, "event_project")

    if ap_rt && ae_rt && ep_rt && project_ids != [] do
      project_event_ids =
        Repo.all(
          from r in Relationship,
            where: r.object_id in ^project_ids and r.relationship_type_id == ^ep_rt.id,
            select: {r.object_id, r.subject_id}
        )
        |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

      biennale_event_set = MapSet.new(biennale_event_ids)

      event_artwork_map =
        Repo.all(
          from r in Relationship,
            where: r.object_id in ^biennale_event_ids and r.relationship_type_id == ^ae_rt.id,
            select: {r.object_id, r.subject_id}
        )
        |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

      artwork_ids =
        event_artwork_map
        |> Enum.flat_map(fn {_eid, aids} -> aids end)
        |> Enum.uniq()

      if artwork_ids == [] do
        %{}
      else
        rels =
          Repo.all(
            from r in Relationship,
              where: r.subject_id in ^artwork_ids and r.relationship_type_id == ^ap_rt.id,
              preload: [:object]
          )

        artwork_participants =
          rels
          |> Enum.group_by(& &1.subject_id)
          |> Enum.into(%{}, fn {artwork_id, rels} ->
            people = rels |> Enum.map(&{&1.object.id, &1.object.identity}) |> Enum.reject(&(elem(&1, 0) == nil))
            {artwork_id, people}
          end)

        for project_id <- project_ids, into: %{} do
          p_event_ids =
            project_event_ids
            |> Map.get(project_id, [])
            |> Enum.filter(&MapSet.member?(biennale_event_set, &1))

          p_artwork_ids = Enum.flat_map(p_event_ids, &Map.get(event_artwork_map, &1, []))
          people = p_artwork_ids |> Enum.flat_map(&Map.get(artwork_participants, &1, [])) |> Enum.uniq()
          {project_id, people}
        end
      end
    else
      %{}
    end
  end

  defp batch_project_directors(project_ids, _rt, _biennale_event_ids) when project_ids == [], do: %{}

  defp batch_project_directors(project_ids, rt, biennale_event_ids) do
    import Ecto.Query, warn: false

    directed_rt = Map.get(rt, "directed")
    sa_rt = Map.get(rt, "screened_at")
    ep_rt = Map.get(rt, "event_project")

    if directed_rt && sa_rt && ep_rt && project_ids != [] do
      project_event_ids =
        Repo.all(
          from r in Relationship,
            where: r.object_id in ^project_ids and r.relationship_type_id == ^ep_rt.id,
            select: {r.object_id, r.subject_id}
        )
        |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

      biennale_event_set = MapSet.new(biennale_event_ids)

      event_film_map =
        Repo.all(
          from r in Relationship,
            where: r.object_id in ^biennale_event_ids and r.relationship_type_id == ^sa_rt.id,
            select: {r.object_id, r.subject_id}
        )
        |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

      film_ids =
        event_film_map
        |> Enum.flat_map(fn {_eid, fids} -> fids end)
        |> Enum.uniq()

      if film_ids == [] do
        %{}
      else
        rels =
          Repo.all(
            from r in Relationship,
              where: r.subject_id in ^film_ids and r.relationship_type_id == ^directed_rt.id,
              preload: [:object]
          )

        film_directors =
          rels
          |> Enum.group_by(& &1.subject_id)
          |> Enum.into(%{}, fn {film_id, rels} ->
            people = rels |> Enum.map(&{&1.object.id, &1.object.identity}) |> Enum.reject(&(elem(&1, 0) == nil))
            {film_id, people}
          end)

        for project_id <- project_ids, into: %{} do
          p_event_ids =
            project_event_ids
            |> Map.get(project_id, [])
            |> Enum.filter(&MapSet.member?(biennale_event_set, &1))

          p_film_ids = Enum.flat_map(p_event_ids, &Map.get(event_film_map, &1, []))
          people = p_film_ids |> Enum.flat_map(&Map.get(film_directors, &1, [])) |> Enum.uniq()
          {project_id, people}
        end
      end
    else
      %{}
    end
  end

  defp batch_event_participants(event_ids, _rt) when event_ids == [], do: %{}

  defp batch_event_participants(event_ids, rt) do
    import Ecto.Query, warn: false

    ae_rt = Map.get(rt, "artwork_event")
    ap_rt = Map.get(rt, "artwork_participant")

    if ae_rt && ap_rt && event_ids != [] do
      event_artwork_map =
        Repo.all(
          from r in Relationship,
            where: r.object_id in ^event_ids and r.relationship_type_id == ^ae_rt.id,
            select: {r.object_id, r.subject_id}
        )
        |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

      artwork_ids =
        event_artwork_map
        |> Enum.flat_map(fn {_eid, aids} -> aids end)
        |> Enum.uniq()

      if artwork_ids == [] do
        %{}
      else
        rels =
          Repo.all(
            from r in Relationship,
              where: r.subject_id in ^artwork_ids and r.relationship_type_id == ^ap_rt.id,
              preload: [:object]
          )

        artwork_participants =
          rels
          |> Enum.group_by(& &1.subject_id)
          |> Enum.into(%{}, fn {artwork_id, rels} ->
            people = rels |> Enum.map(&{&1.object.id, &1.object.identity}) |> Enum.reject(&(elem(&1, 0) == nil))
            {artwork_id, people}
          end)

        for event_id <- event_ids, into: %{} do
          e_artwork_ids = Map.get(event_artwork_map, event_id, [])
          people = e_artwork_ids |> Enum.flat_map(&Map.get(artwork_participants, &1, [])) |> Enum.uniq()
          {event_id, people}
        end
      end
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
