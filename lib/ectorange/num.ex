defmodule EctoRange.Num do
  @moduledoc """
  A Postgres range of `numeric` values. Equivalent to `numrange`.
  Allows numeric values of all precisions.
  Returns `Decimal` structs when loading from the database.

  Watch out: Not defining the precision of your values,
  might cause compatibility problems with other systems in the future.
  """

  use Ecto.Type

  @impl Ecto.Type
  def type, do: :numrange

  @impl Ecto.Type
  def cast(%Postgrex.Range{lower: lower, upper: upper} = range)
      when is_number(lower) and is_number(upper) do
    {:ok, to_postgrex_range(range)}
  end

  def cast(%Postgrex.Range{lower: %Decimal{}, upper: %Decimal{}} = range) do
    {:ok, to_postgrex_range(range)}
  end

  def cast({lower, upper}) when is_number(lower) and is_number(upper) do
    {:ok, to_postgrex_range({lower, upper})}
  end

  def cast({%Decimal{} = lower, %Decimal{} = upper}) do
    {:ok, to_postgrex_range({lower, upper})}
  end

  def cast(_), do: :error

  @impl Ecto.Type
  def dump(%Postgrex.Range{} = range) do
    {:ok, range}
  end

  def dump(_), do: :error

  @impl Ecto.Type
  def load(%Postgrex.Range{} = range) do
    {:ok, normalize_range(range)}
  end

  @doc """
  Checks and converts a `Postgrex.Range` or tuple into a `Postgrex.Range.t()`

  ## Examples

      iex> EctoRange.Date.to_postgrex_range({1, 3})
      %Postgrex.Range{lower: 1, upper: 3, lower_inclusive: true, upper_inclusive: true}

  """
  @spec to_postgrex_range(Postgrex.Range.t() | {number(), number()} | {Decimal.t(), Decimal.t()}) ::
          Postgrex.Range.t()
  def to_postgrex_range(%Postgrex.Range{lower: lower, upper: upper} = range) do
    %Postgrex.Range{
      range
      | lower: if(is_nil(lower), do: :unbound, else: to_decimal(lower)),
        upper: if(is_nil(upper), do: :unbound, else: to_decimal(upper))
    }
  end

  def to_postgrex_range({lower, upper}) do
    %Postgrex.Range{
      lower: if(is_nil(lower), do: :unbound, else: to_decimal(lower)),
      upper: if(is_nil(upper), do: :unbound, else: to_decimal(upper)),
      lower_inclusive: true,
      upper_inclusive: true
    }
  end

  @doc """
  Converts a Postgrex.Range.t() into a normalized form. For bounded ranges,
  it will make the lower and upper bounds inclusive.

  All upper and lower bounds are converted to `%Decimal{}` structs, if necessary.

  ## Examples

      iex> range = %Postgrex.Range{lower: 1, upper: 3, lower_inclusive: true, upper_inclusive: false}
      iex> EctoRange.Num.normalize_range(range)
      %Postgrex.Range{lower: %Decimal{coef: 1}, upper: %Decimal{coef: 2999999999, exp: -9}, lower_inclusive: true, upper_inclusive: true}

      iex> range = %Postgrex.Range{lower: 1, upper: 3, lower_inclusive: false, upper_inclusive: true}
      iex> EctoRange.Num.normalize_range(range)
      %Postgrex.Range{lower: %Decimal{coef: 1000000001, exp: -9}, upper: %Decimal{coef: 3}, lower_inclusive: true, upper_inclusive: true}

  """
  def normalize_range(%Postgrex.Range{} = range) do
    range
    |> normalize_upper()
    |> normalize_lower()
  end

  defp normalize_upper(%Postgrex.Range{upper: upper} = range) do
    if range.upper_inclusive do
      %{range | upper: to_decimal(upper)}
    else
      %{
        range
        | upper_inclusive: true,
          upper: Decimal.sub(to_decimal(range.upper), to_decimal(0.000000001))
      }
    end
  end

  defp normalize_lower(%Postgrex.Range{lower: lower} = range) do
    if range.lower_inclusive do
      %{range | lower: to_decimal(lower)}
    else
      %{
        range
        | lower_inclusive: true,
          lower: Decimal.add(to_decimal(range.lower), to_decimal(0.000000001))
      }
    end
  end

  defp to_decimal(value) when is_integer(value), do: Decimal.new(value)
  defp to_decimal(value) when is_float(value), do: Decimal.from_float(value)
  defp to_decimal(value), do: value
end
