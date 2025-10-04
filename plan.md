# Mykonos Biennale - Development Plan

## Overview
Building a dark, artistic, experimental website for the Mykonos Biennale arts and short film festival with mobile-first design, admin backend, and Tailwind CSS.

## Progress Tracker
- [x] Generate Phoenix LiveView project `mykonos_biennale` with SQLite
- [x] Create plan.md and start development server
- [x] Replace default home page with dark artistic static mockup
- [x] Match layouts to dark experimental design
  - [x] Update `app.css` with dark theme
  - [x] Update `root.html.heex` (force dark theme)
  - [x] Update `<Layouts.app>` component
- [x] Set up authentication with `mix phx.gen.auth` for admin access
- [x] Database schemas and contexts (Step 5 of 8 complete!)
  - [x] Biennale schema (year, theme, statement, description, dates)
  - [x] Event schema (title, type, date, location, description, biennale_id)
  - [x] Content context with full CRUD operations
  - [x] Migration with both tables, indexes, and constraints
- [x] Create public-facing home page (Step 10 of 12 complete!)
  - [x] BiennaleLive - displays current/featured biennale (2025)
  - [x] Auto-creates default 2025 biennale if missing
  - [x] Program preview cards (6 event types)
  - [x] Archive teaser (2024, 2022, 2015, 2013)
  - [x] Dark dramatic design matching mockup
  - [x] Router updated with `/` route
- [x] Create archive pages (Step 15 of 15 complete!)
  - [x] Archive list page showing all biennales
  - [x] Archive detail page showing specific year with full program
  - [x] Events grouped by type (exhibitions, performances, etc)
  - [x] Dynamic routing for /archive/:year
- [ ] Create remaining public pages
  - [ ] Program/events page (filter by type)
  - [ ] About page
- [ ] Create admin backend
  - [ ] Admin dashboard with navigation
  - [ ] Biennale edition management (CRUD)
  - [ ] Event/program management (CRUD)
- [ ] Visit and verify all functionality

## Design Direction
- **Dark theme** with dramatic typography ✅
- **Experimental aesthetic** - bold, artistic, mysterious ✅
- **Mobile-first** responsive design ✅
- Inspired by existing site: https://www.mykonosbiennale.com

## Technical Stack
- Phoenix 1.8 with LiveView ✅
- SQLite database ✅
- Tailwind CSS v4 + daisyUI ✅
- Authentication via phx.gen.auth ✅

