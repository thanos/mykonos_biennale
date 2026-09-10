defmodule MykonosBiennaleWeb.Admin.TeamLiveTest do
  use MykonosBiennaleWeb.AdminCase

  alias MykonosBiennale.ContentFixtures

  describe "Index" do
    test "lists team members grouped by participant with biennale years and roles", %{conn: conn} do
      biennale = ContentFixtures.biennale_fixture(year: 2025)
      participant = ContentFixtures.participant_fixture(first_name: "Team", last_name: "Member")

      ContentFixtures.create_relationship(biennale, participant, "biennale_team", %{
        "role" => "curator"
      })

      {:ok, _lv, html} = live(conn, ~p"/admin/teams")
      assert html =~ "Team Member"
      assert html =~ "2025"
      assert html =~ "curator"
    end

    test "shows empty state when no team members", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/teams")
      assert html =~ "No team members yet"
    end

    test "renders add team member form", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/teams/new")
      html = lv |> element("#team-member-modal") |> render()
      assert html =~ "Add Team Member"
      assert html =~ "Select role..."
    end
  end
end
