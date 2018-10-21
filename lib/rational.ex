defmodule Rational do
  @type t() :: %__MODULE__{p: integer(), q: pos_integer()}
  defstruct p: 0, q: 1

  @spec new(binary() | Decimal.t() | float() | integer() | t()) :: t()
  def new(numerator) when is_binary(numerator) do
    from_binary(numerator)
  end

  def new(decimal = %Decimal{}) do
    from_decimal(decimal)
  end

  def new(numerator) when is_float(numerator) do
    from_float(numerator)
  end

  def new(numerator) when is_integer(numerator) do
    from_integer(numerator)
  end

  def new(rational = %__MODULE__{p: numerator, q: denominator})
      when is_integer(numerator) and is_integer(denominator) and denominator !== 0 do
    rational
  end

  @spec new(integer(), 0) :: no_return()
  @spec new(integer(), integer()) :: t()
  def new(numerator, 0) when is_integer(numerator) do
    :erlang./(numerator, 0)
  end

  def new(numerator, denominator) when is_integer(numerator) and is_integer(denominator) do
    simplify(%__MODULE__{p: numerator, q: denominator})
  end

  ## Basic Arithmetic

  @spec add(t(), t()) :: t()
  def add(%__MODULE__{p: n1, q: denominator}, %__MODULE__{p: n2, q: denominator}) do
    new(:erlang.+(n1, n2), denominator)
  end

  def add(%__MODULE__{p: n1, q: d1}, %__MODULE__{p: n2, q: d2}) do
    new(:erlang.+(:erlang.*(n1, d2), :erlang.*(n2, d1)), :erlang.*(d1, d2))
  end

  @spec subtract(t(), t()) :: t()
  def subtract(%__MODULE__{p: n1, q: denominator}, %__MODULE__{p: n2, q: denominator}) do
    new(:erlang.-(n1, n2), denominator)
  end

  def subtract(%__MODULE__{p: n1, q: d1}, %__MODULE__{p: n2, q: d2}) do
    new(:erlang.-(:erlang.*(n1, d2), :erlang.*(d1, n2)), :erlang.*(d1, d2))
  end

  @spec multiply(t(), t()) :: t()
  def multiply(%__MODULE__{p: n1, q: d1}, %__MODULE__{p: n2, q: d2}) do
    new(:erlang.*(n1, n2), :erlang.*(d1, d2))
  end

  @spec divide(t(), t()) :: t()
  def divide(%__MODULE__{p: n1, q: d1}, %__MODULE__{p: n2, q: d2}) do
    new(:erlang.*(n1, d2), :erlang.*(d1, n2))
  end

  ## Unary Operations

  @spec absolute(t()) :: t()
  def absolute(%__MODULE__{p: numerator, q: denominator}) do
    new(:erlang.abs(numerator), denominator)
  end

  @spec ceiling(t()) :: t()
  def ceiling(number = %__MODULE__{p: numerator, q: denominator}) do
    floor_number = __MODULE__.floor(number)

    if new(numerator, denominator) === floor_number do
      floor_number
    else
      __MODULE__.add(floor_number, new(1))
    end
  end

  @spec floor(t()) :: t()
  def floor(%__MODULE__{p: numerator, q: denominator}) do
    new(Integer.floor_div(numerator, denominator))
  end

  @spec negate(t()) :: t()
  def negate(%__MODULE__{p: numerator, q: denominator}) do
    %__MODULE__{p: :erlang.-(numerator), q: denominator}
  end

  @spec reciprocal(t()) :: t()
  def reciprocal(%__MODULE__{p: numerator, q: denominator}) do
    new(denominator, numerator)
  end

  ## Other Operations

  def compare(%__MODULE__{p: a, q: b}, %__MODULE__{p: c, q: d}) do
    x = :erlang.*(a, d)
    y = :erlang.*(b, c)

    cond do
      :erlang.>(x, y) -> :gt
      :erlang.<(x, y) -> :lt
      :erlang.==(x, y) -> :eq
    end
  end

  def sign(%__MODULE__{p: numerator}) do
    if :erlang.<(numerator, 0), do: :erlang.-(1), else: 1
  end

  ## Conversion

  @spec from_binary(binary()) :: t()
  def from_binary(numerator) when is_binary(numerator) do
    from_binary(numerator, 1)
  end

  @spec from_binary(binary(), pos_integer()) :: t()
  def from_binary(numerator, denominator) when is_binary(numerator) and is_integer(denominator) do
    from_decimal(Decimal.new(numerator), denominator)
  end

  @spec from_decimal(Decimal.t()) :: t()
  def from_decimal(numerator = %Decimal{}) do
    from_decimal(numerator, 1)
  end

  @spec from_decimal(Decimal.t(), pos_integer()) :: t()
  def from_decimal(%Decimal{sign: sign, coef: coef, exp: exp}, denominator)
      when is_integer(exp) and exp >= 0 and is_integer(denominator) do
    new(:erlang.*(sign, :erlang.*(coef, intpow(10, :erlang.abs(exp)))), 1 * denominator)
  end

  def from_decimal(%Decimal{sign: sign, coef: coef, exp: exp}, denominator)
      when is_integer(exp) and exp < 0 and is_integer(denominator) do
    new(:erlang.*(sign, coef), intpow(10, :erlang.abs(exp)) * denominator)
  end

  @spec from_float(float()) :: t()
  def from_float(numerator) when is_float(numerator) do
    from_float(numerator, 1)
  end

  @spec from_float(float(), pos_integer()) :: t()
  def from_float(numerator, denominator) when numerator == trunc(numerator) and is_integer(denominator) do
    new(trunc(numerator), denominator)
  end

  def from_float(numerator, denominator) when is_float(numerator) and is_integer(denominator) do
    from_decimal(Decimal.new(numerator), denominator)
    # from_float(numerator * 10, denominator * 10)
  end

  @spec from_integer(integer()) :: t()
  def from_integer(numerator) when is_integer(numerator) do
    from_integer(numerator, 1)
  end

  @spec from_integer(integer(), pos_integer()) :: t()
  def from_integer(numerator, denominator) when is_integer(numerator) and is_integer(denominator) do
    new(numerator, denominator)
  end

  @spec to_binary(t()) :: binary()
  def to_binary(rational = %__MODULE__{}) do
    maybe_trim_binary_mantissa(Decimal.to_string(to_decimal(rational), :normal))
  end

  @spec to_binary(t(), Decimal.Context.t() | Keyword.t()) :: binary()
  def to_binary(rational = %__MODULE__{}, opts) do
    maybe_trim_binary_mantissa(Decimal.to_string(to_decimal(rational, opts), :normal))
  end

  @spec to_decimal(t()) :: Decimal.t()
  def to_decimal(%__MODULE__{p: numerator, q: denominator}) do
    Decimal.div(numerator, denominator)
  end

  @spec to_decimal(t(), Decimal.Context.t() | Keyword.t()) :: Decimal.t()
  def to_decimal(%__MODULE__{p: numerator, q: denominator}, new_context = %Decimal.Context{}) do
    old_context = Decimal.get_context()
    :ok = Decimal.set_context(new_context)

    try do
      Decimal.div(numerator, denominator)
    after
      :ok = Decimal.set_context(old_context)
    end
  end

  def to_decimal(rational = %__MODULE__{p: numerator, q: denominator}, opts) when is_list(opts) do
    extra = %{characteristic: nil}
    old_context = %Decimal.Context{} = Decimal.get_context()
    {extra, new_context} = parse_decimal_options([:characteristic, :precision, :rounding, :flags, :traps], opts, extra, old_context)
    %{characteristic: characteristic} = extra
    %{precision: precision} = new_context

    case characteristic do
      nil ->
        to_decimal(rational, new_context)

      :infinity ->
        integral_characteristic = :erlang.div(numerator, denominator)

        if integral_characteristic === 0 do
          to_decimal(rational, new_context)
        else
          digits = intlog10(integral_characteristic)
          to_decimal(rational, %{new_context | precision: digits + precision})
        end

      _ when is_integer(characteristic) and characteristic > 0 ->
        integral_characteristic = :erlang.div(numerator, denominator)

        if integral_characteristic === 0 do
          to_decimal(rational, new_context)
        else
          digits = intlog10(integral_characteristic)
          rational_characteristic = new(integral_characteristic)
          rational_mantissa = __MODULE__.subtract(rational, rational_characteristic)
          decimal_characteristic = to_decimal(rational_characteristic, %{new_context | precision: characteristic})
          decimal_mantissa = to_decimal(rational_mantissa, new_context)
          :ok = Decimal.set_context(%{new_context | precision: digits + precision})

          try do
            Decimal.add(decimal_characteristic, decimal_mantissa)
          after
            :ok = Decimal.set_context(old_context)
          end
        end
    end
  end

  @spec to_float(t()) :: float()
  def to_float(rational = %__MODULE__{}) do
    Decimal.to_float(to_decimal(rational))
  end

  @spec to_float(t(), Decimal.Context.t() | Keyword.t()) :: float()
  def to_float(rational = %__MODULE__{}, opts) do
    Decimal.to_float(to_decimal(rational, opts))
  end

  @spec to_integer(t()) :: integer()
  def to_integer(rational = %__MODULE__{}) do
    Decimal.to_integer(to_decimal(rational, characteristic: :infinity, precision: 0))
  end

  @spec to_integer(t(), Decimal.Context.t() | Keyword.t()) :: integer()
  def to_integer(rational = %__MODULE__{}, context = %Decimal.Context{}) do
    Decimal.to_integer(to_decimal(rational, context))
  end

  def to_integer(rational = %__MODULE__{}, opts) when is_list(opts) do
    opts = Keyword.put_new(opts, :characteristic, :infinity)
    opts = Keyword.put_new(opts, :precision, 0)
    Decimal.to_integer(to_decimal(rational, opts))
  end

  @doc false
  defp gcd(a, 0) when is_integer(a), do: :erlang.abs(a)
  defp gcd(0, b) when is_integer(b), do: :erlang.abs(b)
  defp gcd(a, b) when is_integer(a) and is_integer(b), do: gcd(b, :erlang.rem(a, b))

  # Calls `intlog10f/1` and then `intlog10i/1` as fallback if needed.
  @doc false
  defp intlog10(x) when is_integer(x) do
    x = :erlang.abs(x)

    try do
      intlog10f(x)
    catch
      :error, :badarith ->
        intlog10i(x)
    end
  end

  # Fast float-based log10 operation. Errors if `x` is too large.
  @doc false
  defp intlog10f(0) do
    1
  end

  defp intlog10f(1) do
    1
  end

  defp intlog10f(x) when is_integer(x) and x > 0 do
    trunc(:math.ceil(:math.log10(x)))
  end

  # Slow integer-based log10 operation.
  @doc false
  defp intlog10i(x) when is_integer(x) and x > 0 do
    intlog10i(x, 1)
  end

  @doc false
  defp intlog10i(x, n) when is_integer(x) and x > 0 and is_integer(n) and n > 0 do
    cond do
      x >= 100_000_000 -> intlog10i(:erlang.div(x, 100_000_000), n + 8)
      x >= 10000 -> intlog10i(:erlang.div(x, 10000), n + 4)
      x >= 100 -> intlog10i(:erlang.div(x, 100), n + 2)
      x >= 10 -> intlog10i(:erlang.div(x, 10), n + 1)
      true -> n
    end
  end

  @doc false
  def intpow(b, 0) when is_integer(b) do
    1
  end

  def intpow(b, e) when is_integer(b) and is_integer(e) and e > 0 do
    case b do
      0 -> 0
      1 -> 1
      2 -> :erlang.bsl(1, e)
      _ -> intpow(b, e, 1)
    end
  end

  @doc false
  defp intpow(b, e, r) when rem(e, 2) === 0 do
    intpow(b * b, :erlang.div(e, 2), r)
  end

  defp intpow(b, e, r) when div(e, 2) === 0 do
    b * r
  end

  defp intpow(b, e, r) do
    intpow(b * b, :erlang.div(e, 2), b * r)
  end

  @doc false
  def maybe_trim_binary_mantissa(binary) when is_binary(binary) do
    case :binary.split(binary, <<?.>>) do
      [_] ->
        binary

      [characteristic, mantissa] ->
        case String.trim_trailing(mantissa, <<?0>>) do
          <<>> ->
            characteristic

          trimmed_mantissa ->
            <<characteristic::binary(), ?., trimmed_mantissa::binary()>>
        end
    end
  end

  @doc false
  defp normalize(denominator, numerator) when is_integer(denominator) and is_integer(numerator) do
    if :erlang.<(denominator, 0) do
      {:erlang.-(denominator), :erlang.-(numerator)}
    else
      {denominator, numerator}
    end
  end

  @doc false
  defp parse_decimal_options([], [], extra, context) do
    {extra, context}
  end

  defp parse_decimal_options(keys = [], bad_options, extra, context) do
    :erlang.error({:badarg, [keys, bad_options, extra, context]})
  end

  defp parse_decimal_options([key | keys], options, extra, context) do
    case :lists.keytake(key, 1, options) do
      {:value, {^key, value}, new_options}
      when key == :characteristic and ((is_integer(value) and value > 0) or value === :infinity) ->
        extra = :maps.update(key, value, extra)
        parse_decimal_options(keys, new_options, extra, context)

      {:value, {^key, value}, new_options} when key == :precision and is_integer(value) and value >= 0 ->
        context = :maps.update(key, value, context)
        parse_decimal_options(keys, new_options, extra, context)

      {:value, {^key, value}, new_options} when key == :rounding and is_atom(value) and not is_nil(value) ->
        context = :maps.update(key, value, context)
        parse_decimal_options(keys, new_options, extra, context)

      {:value, {^key, value}, new_options} when key in [:flags, :traps] and is_list(value) ->
        context = :maps.update(key, value, context)
        parse_decimal_options(keys, new_options, extra, context)

      false ->
        parse_decimal_options(keys, options, extra, context)
    end
  end

  @doc false
  defp simplify(%__MODULE__{p: numerator, q: denominator}) do
    greatest_common_divisor = gcd(numerator, denominator)
    new_denominator = :erlang.div(denominator, greatest_common_divisor)
    new_numerator = :erlang.div(numerator, greatest_common_divisor)
    {new_denominator, new_numerator} = normalize(new_denominator, new_numerator)
    %__MODULE__{p: new_numerator, q: new_denominator}
  end
end
