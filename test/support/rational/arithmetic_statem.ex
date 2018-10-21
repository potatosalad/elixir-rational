defmodule Rational.ArithmeticStateM do
  use PropCheck
  use PropCheck.StateM

  alias Rational.ArithmeticModel, as: Model
  alias Rational.ArithmeticShim, as: Shim

  @impl :proper_statem
  def initial_state() do
    # structure: {system, model}
    {nil, Model.new()}
  end

  @impl :proper_statem
  def command({nil, _}) do
    rounding_gen =
      oneof([
        :down,
        :half_up,
        :half_even,
        :ceiling,
        :floor,
        :half_down,
        :up
      ])

    return({:call, Shim, :setup, [28, rounding_gen, integer()]})
  end

  def command({system, _model}) do
    oneof([
      {:call, Shim, :add, [system, integer()]},
      {:call, Shim, :subtract, [system, integer()]},
      {:call, Shim, :multiply, [system, integer()]},
      {:call, Shim, :divide, [system, non_zero_integer()]}
    ])
  end

  @impl :proper_statem
  def precondition({nil, _model}, {:call, _, :setup, [_, _, _]}) do
    true
  end

  def precondition({_system, _model}, {:call, _, operation, [_, _]}) when operation in [:add, :subtract, :multiply, :divide] do
    true
  end

  @impl :proper_statem
  def postcondition({nil, _model}, {:call, _, :setup, [_, _, _]}, _result) do
    true
  end

  def postcondition({_system, model}, {:call, shim, operation, [_, other]}, result)
      when operation in [:add, :subtract, :multiply, :divide] do
    Model.check(model, {operation, [other]}, {shim, :to_decimal, [result]})
  end

  @impl :proper_statem
  def next_state({nil, model}, system, {:call, _, :setup, [precision, rounding, value]}) do
    {:ok, model} = Model.setup(model, precision, rounding, value)
    {system, model}
  end

  def next_state({_, model}, system, {:call, _, operation, [_, other]}) do
    {:ok, model} = apply(Model, operation, [model, other])
    {system, model}
  end

  def non_zero_integer() do
    such_that(i <- integer(), when: i !== 0)
  end
end
