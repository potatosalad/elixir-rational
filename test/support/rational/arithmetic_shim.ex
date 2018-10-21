defmodule Rational.ArithmeticShim do
  def setup(_precision, _rounding, value) do
    Rational.new(value)
  end

  def to_decimal(value, options) do
    Rational.to_decimal(value, options)
  end

  def to_float(value, options) do
    Rational.to_float(value, options)
  end

  def add(value, other) do
    Rational.add(value, Rational.new(other))
  end

  def subtract(value, other) do
    Rational.subtract(value, Rational.new(other))
  end

  def multiply(value, other) do
    Rational.multiply(value, Rational.new(other))
  end

  def divide(value, other) do
    Rational.divide(value, Rational.new(other))
  end
end
