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
- [ ] Create public-facing pages
  - [ ] Home/current biennale page (dark, dramatic design)
  - [ ] Archive page (past biennales 2013-2025)
  - [ ] Program/events page (exhibitions, performances, video graffiti, dramatic nights)
  - [ ] About page
- [ ] Create admin backend
  - [ ] Admin dashboard with navigation
  - [ ] Biennale edition management (CRUD)
  - [ ] Event/program management (CRUD)
- [ ] Update router with all public and admin routes
- [ ] Visit and verify functionality

## Design Direction
- **Dark theme** with dramatic typography
- **Experimental aesthetic** - bold, artistic, mysterious
- **Mobile-first** responsive design
- Inspired by existing site: https://www.mykonosbiennale.com

## Technical Stack
- Phoenix 1.8 with LiveView
- SQLite database
- Tailwind CSS v4 + daisyUI
- Authentication via phx.gen.auth

