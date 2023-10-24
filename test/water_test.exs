defmodule WaterTest do
  use ExUnit.Case
  doctest Water

  test "greets the world" do
    assert Water.hello() == :world
  end
end
