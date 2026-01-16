# Migration Plan: Replace Biennale/Event with Entity/Relationship

## Overview
Replace the specialized Biennale and Event schemas with the flexible Entity/Relationship model while preserving all existing functionality and data.

## Estimated Steps: 18 total

---

## Phase 1: Data Migration (3 steps)

### Step 1: Create data migration script
- Create `priv/repo/migrations/[timestamp]_migrate_biennales_events_to_entities.exs`
- Copy all Biennale records → Entity records (type: "biennale")
  - Map fields: year → fields["year"], theme → fields["theme"], etc.
  - Store all biennale data in the flexible `fields` JSON column
- Copy all Event records → Entity records (type: "event")
  - Map fields: title → identity, event_type → fields["event_type"], etc.
- Create Relationship records linking events to biennales
  - name: "belongs_to_biennale"
  - slug: "biennale_event"
  - subject_id: event entity
  - object_id: biennale entity

### Step 2: Run the migration
- Execute `mix ecto.migrate`
- Verify data integrity with test queries

### Step 3: Create helper functions in Content context
- Add `list_biennales/0` - filters entities where type == "biennale", orders by fields["year"] desc
- Add `get_biennale_by_year/1` - finds entity where type == "biennale" and fields["year"] == year
- Add `list_events_for_biennale/1` - uses relationships to find events linked to a biennale
- Add `create_biennale/1` - creates entity with type "biennale" and structured fields
- Add `create_event/1` - creates entity with type "event" and creates relationship
- Keep same function signatures as before for backward compatibility

---

## Phase 2: Update Admin LiveViews (6 steps)

### Step 4: Update Admin.DashboardLive
- Replace Content.list_biennales() calls with new helper
- Replace Content.list_events() calls with new helper
- Update template to render entity.fields instead of direct attributes
- Fix routing warning by using correct entity ID path

### Step 5: Update Admin.BiennaleIndexLive
- Replace Content.list_biennales() with new helper
- Update template to access fields["year"], fields["theme"] from entities
- Update delete functionality to use Content.delete_entity/1

### Step 6: Update Admin.BiennaleFormLive (new/edit)
- Replace Biennale changeset with Entity changeset
- Map form fields to entity.fields JSON structure
- Update save logic to use Content.create_entity/1 and Content.update_entity/1
- Ensure year, theme, description, etc. are stored in fields map

### Step 7: Update Admin.EventIndexLive
- Replace Content.list_events() with new helper
- Update template to access fields["event_type"], fields["title"] from entities
- Update filtering logic for event types using fields["event_type"]

### Step 8: Update Admin.EventFormLive (new/edit)
- Replace Event changeset with Entity changeset
- Map form fields to entity.fields JSON structure
- Create or update relationship when saving event with biennale
- Store event_type, title, description, date, time, location, tickets in fields

### Step 9: Update router
- Replace biennale routes to use entity IDs
- Replace event routes to use entity IDs
- Fix the routing warning we saw during compilation

---

## Phase 3: Update Public LiveViews (4 steps)

### Step 10: Update ArchiveLive
- Replace Content.list_biennales() with new helper
- Update template to render entity.fields["year"], entity.fields["theme"]
- Update navigation links to use entity IDs

### Step 11: Update ProgramLive
- Replace biennale lookup with new helper
- Replace event listing with new relationship-based helper
- Update template to render entity.fields for events
- Update filtering by event type using fields["event_type"]

### Step 12: Update HomeLive
- Replace current biennale lookup with new helper
- Replace event listing with new helper
- Update template to render entity.fields

### Step 13: Update AboutLive (if needed)
- Check if any biennale/event references exist
- Update accordingly

---

## Phase 4: Cleanup (3 steps)

### Step 14: Remove old CRUD functions from Content context
- Remove old create_biennale, update_biennale, delete_biennale
- Remove old create_event, update_event, delete_event
- Keep helper functions that maintain same interface

### Step 15: Drop old tables
- Create migration to drop `biennales` and `events` tables
- Run migration

### Step 16: Delete old schema files
- Delete `lib/mykonos_biennale/content/biennale.ex`
- Delete `lib/mykonos_biennale/content/event.ex`
- Remove from Content context aliases

---

## Phase 5: Testing & Verification (2 steps)

### Step 17: Manual testing
- Test admin dashboard - view all biennales and events
- Test creating new biennale (as entity)
- Test creating new event (as entity with relationship)
- Test editing biennale and event
- Test deleting biennale and event
- Test public archive page
- Test public program page
- Test public home page
- Test event filtering by type

### Step 18: Final compilation and server check
- Run `mix compile` to ensure no warnings
- Visit app with `web http://localhost:4000`
- Verify all functionality works as before

---

## Rollback Plan
If issues arise, we can:
1. Revert migrations (mix ecto.rollback)
2. Restore old LiveView code from git
3. The old biennales/events tables will still have the original data

---

## Notes
- The Entity/Relationship model is more flexible for future features
- All existing functionality will be preserved
- Data is migrated, not lost
- Helper functions maintain backward compatibility in function signatures

