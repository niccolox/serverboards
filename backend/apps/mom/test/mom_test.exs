defmodule Serverboards.MOMTest do
  use ExUnit.Case
  doctest Serverboards.MOM
  doctest Serverboards.MOM.Channel
  doctest Serverboards.MOM.Channel.Named
  doctest Serverboards.MOM.Tap
  doctest Serverboards.MOM.Endpoint.RPC

  test "the truth" do
    assert 1 + 1 == 2
  end
end
