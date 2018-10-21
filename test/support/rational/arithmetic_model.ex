defmodule Rational.ArithmeticModel do
  @type t() :: %__MODULE__{
          precision: pos_integer(),
          rounding: Decimal.rounding(),
          value: Decimal.t()
        }
  defstruct precision: nil, rounding: nil, value: nil

  def new() do
    %__MODULE__{}
  end

  def check(model = %__MODULE__{precision: precision, rounding: rounding}, {mfun, margs}, {shim, sfun, sargs}) do
    {:ok, %{value: mvalue}} = apply(__MODULE__, mfun, [model | margs])
    mvalue = Decimal.with_context(%Decimal.Context{precision: precision, rounding: rounding}, fn -> Decimal.div(mvalue, 1) end)
    svalue = apply(shim, sfun, sargs ++ [[precision: precision, rounding: rounding]])

    case Decimal.cmp(mvalue, svalue) do
      :eq ->
        true

      comparison ->
        diff =
          Decimal.with_context(%Decimal.Context{precision: precision, rounding: rounding}, fn -> Decimal.sub(mvalue, svalue) end)

        if Decimal.cmp(diff, Decimal.new("1E-10")) == :lt do
          true
        else
          IO.puts(
            :io_lib.format(
              <<
                "Model and System have diverged: ~s ~s ~s ~s~n"
              >>,
              [
                inspect(mvalue, limit: :infinity, pretty: true, syntax_colors: IEx.Config.color(:syntax_colors)),
                inspect(comparison, limit: :infinity, pretty: true, syntax_colors: IEx.Config.color(:syntax_colors)),
                inspect(svalue, limit: :infinity, pretty: true, syntax_colors: IEx.Config.color(:syntax_colors)),
                inspect({margs, diff}, limit: :infinity, pretty: true, syntax_colors: IEx.Config.color(:syntax_colors))
              ]
            )
          )

          false
        end
    end
  end

  def setup(model = %__MODULE__{}, precision, rounding, value)
      when is_integer(precision) and precision >= 0 and is_atom(rounding) do
    model = %__MODULE__{precision: precision, rounding: rounding}
    value = with_context(model, fn -> Decimal.new(value) end)
    model = %__MODULE__{model | value: value}
    {:ok, model}
  end

  def add(model = %__MODULE__{value: value}, other) do
    value = with_context(model, fn -> Decimal.add(value, Decimal.new(other)) end)
    model = %__MODULE__{model | value: value}
    {:ok, model}
  end

  def subtract(model = %__MODULE__{value: value}, other) do
    value = with_context(model, fn -> Decimal.sub(value, Decimal.new(other)) end)
    model = %__MODULE__{model | value: value}
    {:ok, model}
  end

  def multiply(model = %__MODULE__{value: value}, other) do
    value = with_context(model, fn -> Decimal.mult(value, Decimal.new(other)) end)
    model = %__MODULE__{model | value: value}
    {:ok, model}
  end

  def divide(model = %__MODULE__{value: value}, other) do
    value = with_context(model, fn -> Decimal.div(value, Decimal.new(other)) end)
    model = %__MODULE__{model | value: value}
    {:ok, model}
  end

  @doc false
  defp with_context(%__MODULE__{precision: precision, rounding: rounding}, fun) when is_function(fun, 0) do
    Decimal.with_context(%Decimal.Context{precision: precision * 10, rounding: rounding}, fun)
  end
end
