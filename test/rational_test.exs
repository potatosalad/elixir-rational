defmodule RationalTest do
  use ExUnit.Case
  use PropCheck

  test("characteristic and precision") do
    rational = Rational.new(100_000_000_000_000_000_000_000_000_000_000, 7)
    assert("14285714285714285714285714290000" == Rational.to_binary(rational, precision: 28, rounding: :half_up))
    assert("14285714285714285714285714280000" == Rational.to_binary(rational, precision: 28, rounding: :half_down))
    assert("14285714285714285714285714285714" == Rational.to_binary(rational, precision: 32, rounding: :half_up))

    assert(
      "14285714285714285714285714285714.29" ==
        Rational.to_binary(rational, characteristic: :infinity, precision: 2, rounding: :half_up)
    )

    assert(
      "14285714285714285714285714285714.28" ==
        Rational.to_binary(rational, characteristic: :infinity, precision: 2, rounding: :half_down)
    )

    assert(
      "14285714285714285714285714290000.29" == Rational.to_binary(rational, characteristic: 28, precision: 2, rounding: :half_up)
    )

    assert(
      "14285714285714285714285714280000.28" == Rational.to_binary(rational, characteristic: 28, precision: 2, rounding: :half_down)
    )
  end

  property("binary float numerator", [{:numtests, 1000}]) do
    forall(numerator <- binary_float()) do
      [characteristic, mantissa] = :binary.split(String.trim_trailing(numerator, "0"), <<?.>>)
      precision = byte_size(characteristic) + byte_size(mantissa)
      rational = Rational.new(numerator)
      lhs = Rational.to_binary(rational, precision: precision)
      rhs = encode_binary_float(characteristic, mantissa)

      (lhs === rhs)
      |> when_fail(print_comparison_failure_report(lhs, rhs))
    end
  end

  property("binary float numerator and denominator", [{:numtests, 1000}]) do
    forall({numerator, denominator} <- {binary_float(), non_zero_integer()}) do
      [characteristic, mantissa] = :binary.split(String.trim_trailing(numerator, "0"), <<?.>>)
      precision = byte_size(characteristic) + byte_size(mantissa)
      rational = Rational.from_binary(numerator, denominator)
      lhs = Rational.to_binary(rational, precision: precision)

      rhs =
        Decimal.with_context(%Decimal.Context{precision: precision}, fn ->
          Decimal.to_string(Decimal.div(Decimal.new(numerator), Decimal.new(denominator)), :normal)
        end)

      rhs = rhs |> String.trim_trailing("0") |> String.trim_trailing(".")

      rhs =
        if rhs === "-0" do
          "0"
        else
          rhs
        end

      (lhs === rhs)
      |> when_fail(print_comparison_failure_report(lhs, rhs))
    end
  end

  property("binary integer numerator", [{:numtests, 1000}]) do
    forall(numerator <- binary_integer()) do
      precision = byte_size(numerator)
      rational = Rational.new(numerator)
      lhs = Rational.to_binary(rational, precision: precision)
      rhs = encode_binary_float(numerator, <<>>)

      (lhs === rhs)
      |> when_fail(print_comparison_failure_report(lhs, rhs))
    end
  end

  property("binary integer numerator and denominator", [{:numtests, 1000}]) do
    forall({numerator, denominator} <- {binary_integer(), non_zero_integer()}) do
      precision = byte_size(numerator)
      rational = Rational.from_binary(numerator, denominator)
      lhs = Rational.to_binary(rational, precision: precision)

      rhs =
        Decimal.with_context(%Decimal.Context{precision: precision}, fn ->
          Decimal.to_string(Decimal.div(Decimal.new(numerator), Decimal.new(denominator)), :normal)
        end)

      rhs =
        if String.contains?(rhs, ".") do
          rhs |> String.trim_trailing("0") |> String.trim_trailing(".")
        else
          rhs
        end

      rhs =
        if rhs === "-0" do
          "0"
        else
          rhs
        end

      (lhs === rhs)
      |> when_fail(print_comparison_failure_report(lhs, rhs))
    end
  end

  property("float numerator", [{:numtests, 1000}]) do
    forall(numerator <- float()) do
      rational = Rational.new(numerator)
      lhs = Rational.to_float(rational)
      rhs = numerator

      (lhs === rhs)
      |> when_fail(print_comparison_failure_report(lhs, rhs))
    end
  end

  property("float numerator and denominator", [{:numtests, 1000}]) do
    forall({numerator, denominator} <- {float(), non_zero_integer()}) do
      rational = Rational.from_float(numerator, denominator)
      lhs = Rational.to_float(rational)
      rhs = Decimal.to_float(Decimal.div(Decimal.new(numerator), Decimal.new(denominator)))

      (lhs === rhs)
      |> when_fail(print_comparison_failure_report(lhs, rhs))
    end
  end

  property("integer numerator", [{:numtests, 1000}]) do
    forall(numerator <- integer()) do
      rational = Rational.new(numerator)
      lhs = Rational.to_integer(rational)
      rhs = numerator

      (lhs === rhs)
      |> when_fail(print_comparison_failure_report(lhs, rhs))
    end
  end

  property("integer numerator and denominator", [{:numtests, 1000}]) do
    forall({numerator, denominator} <- {integer(), non_zero_integer()}) do
      rational = Rational.from_integer(numerator, denominator)
      lhs = Rational.to_integer(rational, rounding: :down)
      rhs = :erlang.div(numerator, denominator)

      (lhs === rhs)
      |> when_fail(print_comparison_failure_report(lhs, rhs))
    end
  end

  def binary_float() do
    digit_gen = oneof(Enum.to_list(?0..?9))

    let([
      sign <- oneof(["-", ""]),
      characteristic <- such_that(digits <- non_empty(list(digit_gen)), when: length(digits) === 1 or hd(digits) !== ?0),
      mantissa <- non_empty(list(digit_gen))
    ]) do
      :erlang.iolist_to_binary([sign, characteristic, ?., mantissa])
    end
  end

  def binary_integer() do
    digit_gen = oneof(Enum.to_list(?0..?9))

    let([
      sign <- oneof(["-", ""]),
      characteristic <- such_that(digits <- non_empty(list(digit_gen)), when: length(digits) === 1 or hd(digits) !== ?0)
    ]) do
      :erlang.iolist_to_binary([sign, characteristic])
    end
  end

  def encode_binary_float(characteristic, mantissa) do
    if mantissa === <<>> do
      if characteristic === "-0" do
        "0"
      else
        characteristic
      end
    else
      :erlang.iolist_to_binary([characteristic, ?., mantissa])
    end
  end

  def intlog10(x) when is_integer(x) do
    byte_size(:erlang.integer_to_binary(:erlang.abs(x)))
  end

  def non_zero_integer() do
    such_that(i <- integer(), when: i !== 0)
  end

  @doc false
  defp print_comparison_failure_report(lhs, rhs) do
    IO.puts(
      :io_lib.format(<<"lhs = ~s~n", "rhs = ~s~n">>, [
        inspect(lhs, limit: :infinity, pretty: true),
        inspect(rhs, limit: :infinity, pretty: true)
      ])
    )
  end
end
