defmodule Number.Human do
  @moduledoc """
  Provides functions for converting numbers into more human readable strings.
  """

  import Number.Delimit, only: [number_to_delimited: 2]
  import Decimal, only: [cmp: 2]

  @doc """
  Formats and labels a number with the appropriate English word.

  ## Examples

      iex> Number.Human.number_to_human(123)
      "123.00"

      iex> Number.Human.number_to_human(1234)
      "1.23 Thousand"

      iex> Number.Human.number_to_human(999001)
      "999.00 Thousand"

      iex> Number.Human.number_to_human(1234567)
      "1.23 Million"

      iex> Number.Human.number_to_human(1234567890)
      "1.23 Billion"

      iex> Number.Human.number_to_human(1234567890123)
      "1.23 Trillion"

      iex> Number.Human.number_to_human(1234567890123456)
      "1.23 Quadrillion"

      iex> Number.Human.number_to_human(1234567890123456789)
      "1,234.57 Quadrillion"

      iex> Number.Human.number_to_human(Decimal.new("5000.0"))
      "5.00 Thousand"

      iex> Number.Human.number_to_human('charlist')
      ** (ArgumentError) number must be a float, integer or implement `Number.Conversion` protocol, was 'charlist'

  """
  def number_to_human(number, options \\ [], locale \\ "en_US")

  def number_to_human(number, options, locale) when not is_map(number) do
    if Number.Conversion.impl_for(number) do
      number
      |> Number.Conversion.to_decimal()
      |> number_to_human(options, locale)
    else
      raise ArgumentError,
            "number must be a float, integer or implement `Number.Conversion` protocol, was #{
              inspect(number)
            }"
    end
  end

  def number_to_human(number, options, locale) do
    case locale do
      "zh_CN" -> number_to_human_cn(number, options)
      _ -> number_to_human_en(number, options)
    end
  end

  defp number_to_human_cn(number, options) do
    cond do
      cmp(number, ~d(-1_0000_0000)) in [:lt, :eq] ->
        delimit(number, ~d(-1_0000_0000), "亿", options)
      cmp(number, ~d(-1_0000)) in [:lt, :eq] && cmp(number, ~d(-1_0000_0000)) == :gt ->
        delimit(number, ~d(-1_0000), "万", options)
      cmp(number, ~d(9999)) == :gt && cmp(number, ~d(1_0000_0000)) == :lt ->
        delimit(number, ~d(1_0000), "万", options)

      cmp(number, ~d(1_0000_0000)) in [:gt, :eq] ->
        delimit(number, ~d(1_0000_0000), "亿", options)

      true ->
        number_to_delimited(number, options)
    end
  end

  defp number_to_human_en(number, options) do
    cond do
      cmp(number, ~d(-1_000_000_000_000_000)) == :gt && cmp(number, ~d(-1_000_000_000_000)) in [:lt, :eq] ->
        delimit(number, ~d(-1_000_000_000_000), "t", options)

      cmp(number, ~d(-1_000_000_000_000)) == :gt && cmp(number, ~d(-1_000_000_000)) in [:lt, :eq] ->
        delimit(number, ~d(-1_000_000_000), "b", options)

      cmp(number, ~d(-1_000_000_000)) == :gt && cmp(number, ~d(-1_000_000)) in [:lt, :eq] ->
        delimit(number, ~d(-1_000_000), "m", options)

      cmp(number, ~d(-1_000_000)) == :gt && cmp(number, ~d(-1_000)) in [:lt, :eq] ->
        delimit(number, ~d(-1_000), "k", options)

      cmp(number, ~d(999)) == :gt && cmp(number, ~d(1_000_000)) == :lt ->
        delimit(number, ~d(1_000), "k", options)

      cmp(number, ~d(1_000_000)) in [:gt, :eq] and cmp(number, ~d(1_000_000_000)) == :lt ->
        delimit(number, ~d(1_000_000), "m", options)

      cmp(number, ~d(1_000_000_000)) in [:gt, :eq] and cmp(number, ~d(1_000_000_000_000)) == :lt ->
        delimit(number, ~d(1_000_000_000), "b", options)

      cmp(number, ~d(1_000_000_000_000)) == :gt and cmp(number, ~d(1_000_000_000_000_000)) == :lt ->
        delimit(number, ~d(1_000_000_000_000), "t", options)

      true ->
        number_to_delimited(number, options)
    end
  end

  @doc """
  Adds ordinal suffix (st, nd, rd or th) for the number
  ## Examples

      iex> Number.Human.number_to_ordinal(3)
      "3rd"

      iex> Number.Human.number_to_ordinal(1)
      "1st"

      iex> Number.Human.number_to_ordinal(46)
      "46th"

      iex> Number.Human.number_to_ordinal(442)
      "442nd"

      iex> Number.Human.number_to_ordinal(4001)
      "4001st"

  """
  def number_to_ordinal(number) when is_integer(number) do
    sfx = ~w(th st nd rd th th th th th th)

    Integer.to_string(number) <>
      case rem(number, 100) do
        11 -> "th"
        12 -> "th"
        13 -> "th"
        _ -> Enum.at(sfx, rem(number, 10))
      end
  end

  defp sigil_d(number, _modifiers) do
    number
    |> String.replace("_", "")
    |> String.to_integer()
    |> Decimal.new()
  end

  defp delimit(number, divisor, label, options) do
    number =
      number
      |> Decimal.div(Decimal.abs(divisor))
      |> number_to_delimited(options)

    number <> "" <> label
  end
end
