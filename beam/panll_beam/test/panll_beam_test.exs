defmodule PanllBeamTest do
  use ExUnit.Case

  test "status snapshot shape is stable" do
    status = PanllBeam.Status.snapshot()

    assert status.service == "panll_beam"
    assert status.runtime == "beam"
    assert status.status == "ready"
    assert is_list(status.apis)
    assert is_integer(status.timestamp_unix)
  end

  test "config can limit enabled apis" do
    old = System.get_env("PANLL_BEAM_APIS")
    on_exit(fn -> restore_env("PANLL_BEAM_APIS", old) end)

    System.put_env("PANLL_BEAM_APIS", "http,grpc")
    assert PanllBeam.Config.enabled_apis() == [:http, :grpc]
    assert PanllBeam.Config.enabled?(:http)
    assert PanllBeam.Config.enabled?(:grpc)
    refute PanllBeam.Config.enabled?(:graphql)
  end

  test "graphql exposes health and status queries" do
    assert {:ok, %{data: %{"health" => "ok"}}} =
             Absinthe.run("{ health }", PanllBeam.GraphQL.Schema)

    assert {:ok, %{data: %{"status" => %{"service" => "panll_beam"}}}} =
             Absinthe.run("{ status { service } }", PanllBeam.GraphQL.Schema)
  end

  test "grpc status server returns a valid reply" do
    request = %PanllBeam.GRPC.StatusRequest{}
    reply = PanllBeam.GRPC.StatusServer.get_status(request, nil)

    assert %PanllBeam.GRPC.StatusReply{} = reply
    assert reply.service == "panll_beam"
    assert reply.status == "ready"
    assert reply.runtime == "beam"
  end

  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)
end

defmodule PanllBeamLegacyApiTest do
  use ExUnit.Case

  test "legacy module entry point is available" do
    assert PanllBeam.hello() == :world
  end
end
