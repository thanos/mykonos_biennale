#!/bin/bash
# Script to create GitHub issues for the Entity/Relationship migration plan

echo "Creating GitHub issues for migration plan..."

# Phase 1: Data Migration
gh issue create \
  --title "Phase 1, Step 1: Create data migration script" \
  --body "Create migration to copy Biennale/Event data to Entity/Relationship tables.

- Copy all Biennale records → Entity records (type: 'biennale')
- Map fields: year → fields['year'], theme → fields['theme'], etc.
- Copy all Event records → Entity records (type: 'event')
- Create Relationship records linking events to biennales
  - name: 'belongs_to_biennale'
  - slug: 'biennale_event'
  - subject_id: event entity, object_id: biennale entity" \
  --label "migration,phase-1,step-1"

gh issue create \
  --title "Phase 1, Step 2: Run the data migration" \
  --body "Execute the data migration and verify data integrity.

- Run \`mix ecto.migrate\`
- Verify data integrity with test queries
- Ensure all Biennales and Events are copied correctly" \
  --label "migration,phase-1,step-2"

gh issue create \
  --title "Phase 1, Step 3: Create helper functions in Content context" \
  --body "Add backward-compatible helper functions to Content context.

- Add \`list_biennales/0\` - filters entities where type == 'biennale'
- Add \`get_biennale_by_year/1\` - finds entity by type and year
- Add \`list_events_for_biennale/1\` - uses relationships to find linked events
- Add \`create_biennale/1\` - creates entity with type 'biennale'
- Add \`create_event/1\` - creates entity and relationship
- Keep same function signatures for backward compatibility" \
  --label "migration,phase-1,step-3"

# Phase 2: Update Admin LiveViews
gh issue create \
  --title "Phase 2, Step 4: Update Admin.DashboardLive" \
  --body "Refactor Admin Dashboard to use Entity/Relationship model.

- Replace Content.list_biennales() with new helper
- Replace Content.list_events() with new helper
- Update template to render entity.fields instead of direct attributes
- Fix routing warning by using correct entity ID path" \
  --label "migration,phase-2,step-4,admin"

gh issue create \
  --title "Phase 2, Step 5: Update Admin.BiennaleIndexLive" \
  --body "Refactor Biennale Index page to use Entity model.

- Replace Content.list_biennales() with new helper
- Update template to access fields['year'], fields['theme'] from entities
- Update delete functionality to use Content.delete_entity/1" \
  --label "migration,phase-2,step-5,admin"

gh issue create \
  --title "Phase 2, Step 6: Update Admin.BiennaleFormLive (new/edit)" \
  --body "Refactor Biennale form to use Entity changeset.

- Replace Biennale changeset with Entity changeset
- Map form fields to entity.fields JSON structure
- Update save logic to use Content.create_entity/1 and Content.update_entity/1
- Ensure year, theme, description stored in fields map" \
  --label "migration,phase-2,step-6,admin"

gh issue create \
  --title "Phase 2, Step 7: Update Admin.EventIndexLive" \
  --body "Refactor Event Index page to use Entity model.

- Replace Content.list_events() with new helper
- Update template to access fields['event_type'], fields['title'] from entities
- Update filtering logic for event types using fields['event_type']" \
  --label "migration,phase-2,step-7,admin"

gh issue create \
  --title "Phase 2, Step 8: Update Admin.EventFormLive (new/edit)" \
  --body "Refactor Event form to use Entity changeset and Relationship.

- Replace Event changeset with Entity changeset
- Map form fields to entity.fields JSON structure
- Create or update relationship when saving event with biennale
- Store event_type, title, description, date, time, location, tickets in fields" \
  --label "migration,phase-2,step-8,admin"

gh issue create \
  --title "Phase 2, Step 9: Update router" \
  --body "Update router to use entity IDs and fix routing warning.

- Replace biennale routes to use entity IDs
- Replace event routes to use entity IDs
- Fix the routing warning for /admin/biennales/#{biennale.id}" \
  --label "migration,phase-2,step-9,admin"

# Phase 3: Update Public LiveViews
gh issue create \
  --title "Phase 3, Step 10: Update ArchiveLive" \
  --body "Refactor Archive page to use Entity model.

- Replace Content.list_biennales() with new helper
- Update template to render entity.fields['year'], entity.fields['theme']
- Update navigation links to use entity IDs" \
  --label "migration,phase-3,step-10,public"

gh issue create \
  --title "Phase 3, Step 11: Update ProgramLive" \
  --body "Refactor Program page to use Entity/Relationship model.

- Replace biennale lookup with new helper
- Replace event listing with new relationship-based helper
- Update template to render entity.fields for events
- Update filtering by event type using fields['event_type']" \
  --label "migration,phase-3,step-11,public"

gh issue create \
  --title "Phase 3, Step 12: Update HomeLive" \
  --body "Refactor Home page to use Entity/Relationship model.

- Replace current biennale lookup with new helper
- Replace event listing with new helper
- Update template to render entity.fields" \
  --label "migration,phase-3,step-12,public"

gh issue create \
  --title "Phase 3, Step 13: Update AboutLive (if needed)" \
  --body "Check and update About page if it references biennales/events.

- Check if any biennale/event references exist
- Update accordingly to use Entity model" \
  --label "migration,phase-3,step-13,public"

# Phase 4: Cleanup
gh issue create \
  --title "Phase 4, Step 14: Remove old CRUD functions from Content context" \
  --body "Clean up Content context by removing old Biennale/Event functions.

- Remove old create_biennale, update_biennale, delete_biennale
- Remove old create_event, update_event, delete_event
- Keep helper functions that maintain same interface" \
  --label "migration,phase-4,step-14,cleanup"

gh issue create \
  --title "Phase 4, Step 15: Drop old tables" \
  --body "Create and run migration to drop old database tables.

- Create migration to drop \`biennales\` and \`events\` tables
- Run migration" \
  --label "migration,phase-4,step-15,cleanup"

gh issue create \
  --title "Phase 4, Step 16: Delete old schema files" \
  --body "Remove old schema files from codebase.

- Delete lib/mykonos_biennale/content/biennale.ex
- Delete lib/mykonos_biennale/content/event.ex
- Remove from Content context aliases" \
  --label "migration,phase-4,step-16,cleanup"

# Phase 5: Testing & Verification
gh issue create \
  --title "Phase 5, Step 17: Manual testing" \
  --body "Comprehensive manual testing of all functionality.

- Test admin dashboard - view all biennales and events
- Test creating new biennale (as entity)
- Test creating new event (as entity with relationship)
- Test editing biennale and event
- Test deleting biennale and event
- Test public archive page
- Test public program page
- Test public home page
- Test event filtering by type" \
  --label "migration,phase-5,step-17,testing"

gh issue create \
  --title "Phase 5, Step 18: Final compilation and server check" \
  --body "Final verification that everything works.

- Run \`mix compile\` to ensure no warnings
- Visit app with \`web http://localhost:4000\`
- Verify all functionality works as before" \
  --label "migration,phase-5,step-18,testing"

echo "Done! All GitHub issues created successfully."
