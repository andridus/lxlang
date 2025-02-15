defmodule Elixir.A do
  @doc """
    Something for module A
  """
  def a do
    1
  end

  def b do
    a()
  end
end