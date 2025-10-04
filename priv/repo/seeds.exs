# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MykonosBiennale.Repo.insert!(%MykonosBiennale.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias MykonosBiennale.Accounts

# Create default admin user
{:ok, admin} =
  Accounts.register_user(%{email: "admin@mykonosbiennale.com", password: "adminpassword123"})

{:ok, _admin, _expired_tokens} =
  Accounts.update_user_password(admin, %{password: "adminpassword123"})

IO.puts("✓ Created admin user: admin@mykonosbiennale.com / adminpassword123")
