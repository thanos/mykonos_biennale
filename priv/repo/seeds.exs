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

# Create default admin user (idempotent)
admin =
  case Accounts.get_user_by_email("admin@mykonosbiennale.com") do
    nil ->
      {:ok, user} =
        Accounts.register_user(%{
          email: "admin@mykonosbiennale.com",
          password: "adminpassword123"
        })

      {:ok, user, _expired_tokens} =
        Accounts.update_user_password(user, %{password: "adminpassword123"})

      user

    user ->
      user
  end

IO.puts("✓ Admin user ready: admin@mykonosbiennale.com / adminpassword123")
