defmodule A do
	def a :: float do
		1.0
	end
	def b(arg1) :: integer do
		a()
	end
	def c(arg1 :: integer, arg2 :: bool) :: bool do
		false
	end
end
