defmodule VirtualCrypto.Exterior.Resolver do
  defmacro __using__(opts) do
    module = Keyword.fetch!(opts, :resolvable)

    quote do
      defp grouped(exteriors) do
        exteriors
        |> Enum.with_index()
        |> Enum.group_by(fn {e, _i} -> unquote(module).resolver(e) end)
      end

      defp resolves_(exteriors, f) do
        grouped(exteriors)
        |> Enum.map(fn {k, v} ->
          f.(k, v |> Enum.map(fn {e, _i} -> e end))
          |> Enum.zip(v |> Enum.map(fn {_e, i} -> i end))
        end)
        |> Enum.flat_map(&Function.identity/1)
        |> Enum.sort_by(fn {_e, i} -> i end)
        |> Enum.map(fn {e, _i} -> e end)
      end

      def resolves(exteriors) do
        resolves_(exteriors, fn k, v -> k.resolves(v) end)
      end

      def resolve_ids(exteriors) do
        resolves_(exteriors, fn k, v -> k.resolve_ids(v) end)
      end
    end
  end
end
