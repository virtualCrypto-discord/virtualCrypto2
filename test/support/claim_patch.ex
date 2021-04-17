defmodule InteractionsControllerTest.Claim.Patch do
  def claim_data_id(action, id) do
    %{
      name: "claim",
      options: [
        %{
          name: action,
          options: [
            %{
              name: "id",
              value: id
            }
          ]
        }
      ]
    }
  end

  def execute_from_guild(data, user) do
    %{
      type: 2,
      data: data,
      member: %{
        user: %{
          id: to_string(user)
        }
      }
    }
  end

  def patch_from_guild(action, id, user) do
    execute_from_guild(claim_data_id(action, id), user)
  end

  def list_from_guild(user) do
    execute_from_guild(
      %{
        name: "claim",
        options: [
          %{
            name: "list",
            options: []
          }
        ]
      },
      user
    )
  end
end
