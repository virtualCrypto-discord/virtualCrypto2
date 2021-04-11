defmodule InteractionsControllerTest.Claim.Patch do
  def claim_data(action, id) do
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

  def patch_from_guild(action, id, user) do
    %{
      type: 2,
      data: claim_data(action, id),
      member: %{
        user: %{
          id: to_string(user)
        }
      }
    }
  end






end
