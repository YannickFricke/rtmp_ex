defmodule RTMPTest do
  use ExUnit.Case

  doctest RTMP

  test "greets the world" do
    assert RTMP.hello() == :world
  end
end
