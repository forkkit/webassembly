alias WebAssembly.Core

defmodule Core do
  @moduledoc """
  Core of the markup assembly.

  Consists of two parts:
  * `WebAssembly.Core.St` - a functional state of markup in the current block
  * `WebAssembly.Core.Scope` - a wrapper around state above, allowing for
    mutable operation on it
  """
  require WebAssembly.Types, as: T


  defmodule St do
    @moduledoc """
    State of markup assembly in the current block.
    """

    defstruct stack: []
    @opaque t :: %St{stack: [T.content]}

    @doc """
    Creates new empty state.
    """
    @spec new() :: t
    def new, do: %__MODULE__{}

    @doc """
    Pushes `value` into the `state`.
    """
    @spec push(t, T.content) :: t
    def push(_, %__MODULE__{} = value) do
      raise ArgumentError, "cant push state as a value: #{inspect value}"
    end
    def push(%{stack: s} = state, value) do
      %{state | stack: [value|s]}
    end

    @doc """
    Releases the `state`, returning values in the order of pushing.
    """
    @spec release(t) :: [T.content]
    def release(%{stack: s} = _state), do: Enum.reverse(s)
  end


  defmodule Scope do
    @moduledoc """
      Mutability wrapper around `WebAssembly.Core.St`.

      Internally uses `Agent`s.
    """

    @spec new!() :: pid
    def new! do
      {:ok, pid} = Agent.start_link(fn -> St.new end)
      pid
    end

    @spec push(pid, T.content) :: :ok
    def push(pid, value) do
      Agent.update(pid, fn st0 ->
        St.push(st0, value)
      end)
    end

    @spec release(pid) :: [T.content]
    def release(pid) do
      result = Agent.get(pid, fn st -> St.release(st) end)
      :ok = Agent.stop(pid)
      result
    end
  end
end
