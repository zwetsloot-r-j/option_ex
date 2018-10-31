defmodule OptionEx do
  @moduledoc """
  OptionEx is a module for handling functions returning a `t:OptionEx.t/0`.
  This module is inspired by the f# Option module, and [Railway Oriented Programming](https://fsharpforfunandprofit.com/rop/) as explained by Scott Wlaschin. This module is intended to make working with `nil` values more safe and convenient. For splitting tracks based on ok or error return values see [ResultEx](https://hexdocs.pm/result_ex/ResultEx.html#content).

  The Option type consists of either a {:some, term} where the term represents a value, or the :none atom representing the lack of a value.

  By replacing optional nil values with an `t:OptionEx.t/0`, it is no longer needed to match nil value cases. By using `OptionEx.map/2` or `OptionEx.bind/2` the function passed as second argument will only be executed when a value is present. By using `OptionEx.or_else/2` or `OptionEx.or_else_with/2` it is possible to add a default value, or behaviour to be executed only in case there is no value.

  ## Examples

      iex> find_by_id = fn
      ...>   1 -> nil
      ...>   x -> %{id: x}
      ...> end
      ...>
      ...> find_by_id.(2)
      ...> |> OptionEx.return()
      {:some, %{id: 2}}
      ...>
      ...> find_by_id.(1)
      ...> |> OptionEx.return()
      :none
      ...>
      ...> find_by_id.(2)
      ...> |> OptionEx.return()
      ...> |> OptionEx.map(fn record -> record.id end)
      ...> |> OptionEx.map(&(&1 + 1))
      ...> |> OptionEx.bind(find_by_id)
      {:some, %{id: 3}}
      ...>
      ...> find_by_id.(1)
      ...> |> OptionEx.return()
      ...> |> OptionEx.map(fn record -> record.id end)
      ...> |> OptionEx.map(&(&1 + 1))
      ...> |> OptionEx.bind(find_by_id)
      :none
      ...>
      ...> find_by_id.(2)
      ...> |> OptionEx.return()
      ...> |> OptionEx.or_else_with(fn -> find_by_id.(0) end)
      %{id: 2}
      ...>
      ...> find_by_id.(1)
      ...> |> OptionEx.return()
      ...> |> OptionEx.or_else_with(fn -> find_by_id.(0) end)
      %{id: 0}

  """

  @type t ::
          {:some, term}
          | :none

  @doc """
  Elevates a value to an `t:OptionEx.t/0` type.
  If nil is passed, an empty `t:OptionEx.t/0` will be returned.

  ## Examples

      iex> OptionEx.return(1)
      {:some, 1}

      iex> OptionEx.return(nil)
      :none

  """
  @spec return(term) :: t
  def return(nil), do: :none

  def return(value), do: {:some, value}

  @doc """
  Runs a function against the `t:OptionEx.t/0` value.

  ## Examples

      iex> option = {:some, 1}
      ...> OptionEx.map(option, &(&1 + 1))
      {:some, 2}

      iex> option = :none
      ...> OptionEx.map(option, &(&1 + 1))
      :none 

  """
  @spec map(t, (term -> term)) :: t
  def map({:some, value}, fun) do
    {:some, fun.(value)}
  end

  def map(:none, _), do: :none

  @doc """
  Partially applies `OptionEx.map/2` with the passed function.
  """
  @spec map((term -> term)) :: (t -> t)
  def map(fun) do
    fn option -> map(option, fun) end
  end

  @doc """
  Executes or partially executes the function given as value of the first `t:OptionEx.t/0`,
  and applies it with the value of the second `t:OptionEx.t/0`.
  If the function has an arity greater than 1, the returned `t:OptionEx.t/0` value will be the function partially applied.
  (The function name is 'appl' rather than 'apply' to prevent import conflicts with 'Kernel.apply')

  ## Examples

      iex> value_option = {:some, 1}
      ...> function_option = {:some, fn value -> value + 1 end}
      ...> OptionEx.appl(function_option, value_option)
      {:some, 2}

      iex> {:some, fn value1, value2, value3 -> value1 + value2 + value3 end}
      ...> |> OptionEx.appl({:some, 1})
      ...> |> OptionEx.appl({:some, 2})
      ...> |> OptionEx.appl({:some, 3})
      {:some, 6}

      iex> :none
      ...> |> OptionEx.appl({:some, 1})
      ...> |> OptionEx.appl({:some, 1})
      ...> |> OptionEx.appl({:some, 1})
      :none

      iex> {:some, fn value1, value2, value3 -> value1 + value2 + value3 end}
      ...> |> OptionEx.appl({:some, 1})
      ...> |> OptionEx.appl({:some, 1})
      ...> |> OptionEx.appl(:none)
      :none

  """
  @spec appl(t, t) :: t
  def appl({:some, fun}, {:some, value}) do
    case :erlang.fun_info(fun, :arity) do
      {_, 0} ->
        :none

      _ ->
        {:some, curry(fun, value)}
    end
  end

  def appl(:none, _), do: :none

  def appl(_, :none), do: :none

  @doc """
  Applies a function with the value of the `t:OptionEx.t/0`.
  The passed function is expected to return an `t:OptionEx.t/0`.
  This can be useful for chaining functions that elevate values into options together.

  ## Examples

      iex> head = fn
      ...>   [] -> :none
      ...>   list -> {:some, hd(list)}
      ...> end
      ...> head.([[4]])
      ...> |> OptionEx.bind(head)
      {:some, 4}

      iex> head = fn
      ...>   [] -> :none
      ...>   list -> {:some, hd(list)}
      ...> end
      ...> head.([[]])
      ...> |> OptionEx.bind(head)
      :none

  """
  @spec bind(t, (term -> t)) :: t
  def bind({:some, value}, fun) do
    fun.(value)
  end

  def bind(:none, _), do: :none

  @doc """
  Partially applies `OptionEx.bind/2` with the passed function.
  """
  @spec bind((term -> t)) :: (t -> t)
  def bind(fun) do
    fn option -> bind(option, fun) end
  end

  @doc """
  Unwraps the `t:OptionEx.t/0` to return its value.
  Throws an error if the `t:OptionEx.t/0` is :none.

  ## Examples

      iex> OptionEx.return(5)
      ...> |> OptionEx.unwrap!()
      5

  """
  @spec unwrap!(t) :: term
  def unwrap!({:some, value}), do: value

  def unwrap!(:none), do: throw("OptionEx.unwrap!: The option has no value")

  @doc """
  Unwraps the `t:OptionEx.t/0` to return its value.
  The second argument will be a specific error message to throw when the `t:OptionEx.t/0` is empty.

  ## Examples

      iex> OptionEx.return(5)
      ...> |> OptionEx.expect!("The value was not what was expected")
      5

  """
  @spec expect!(t, String.t()) :: term
  def expect!({:some, value}, _), do: value

  def expect!(_, message), do: throw(message)

  @doc """
  Unwraps the `t:OptionEx.t/0` to return its value.
  If the `t:OptionEx.t/0` is empty, it will return the default value passed as second argument instead.

  ## Examples

      iex> OptionEx.return(5)
      ...> |> OptionEx.or_else(4)
      5

      iex> :none
      ...> |> OptionEx.or_else(4)
      4

  """
  @spec or_else(t, term) :: term
  def or_else({:some, value}, _), do: value

  def or_else(_, default), do: default

  @doc """
  Unwraps the `t:OptionEx.t/0` to return its value.
  If the `t:OptionEx.t/0` is empty, the given function will be applied instead.

  ## Examples

      iex> OptionEx.return(5)
      ...> |> OptionEx.or_else_with(fn -> 4 end)
      5

      iex> :none
      ...> |> OptionEx.or_else_with(fn -> 4 end)
      4

  """
  @spec or_else_with(t, (() -> term)) :: term
  def or_else_with({:some, value}, _), do: value

  def or_else_with(:none, fun), do: fun.()

  @doc """
  Flatten nested `t:OptionEx.t/0`s into one `t:OptionEx.t/0`.

  ## Examples

      iex> OptionEx.return(5)
      ...> |> OptionEx.return()
      ...> |> OptionEx.return()
      ...> |> OptionEx.flatten()
      {:some, 5}

      iex> {:some, {:some, :none}}
      ...> |> OptionEx.flatten()
      :none

  """
  @spec flatten(t) :: t
  def flatten({:some, {:some, _} = inner_result}) do
    flatten(inner_result)
  end

  def flatten({_, :none}), do: :none

  def flatten({:some, _} = result), do: result

  def flatten(:none), do: :none

  @doc """
  Flattens an `t:Enum.t/0` of `t:OptionEx.t/0`s into an `t:OptionEx.t/0` of enumerables.

  ## Examples

      iex> [{:some, 1}, {:some, 2}, {:some, 3}]
      ...> |> OptionEx.flatten_enum()
      {:some, [1, 2, 3]}

      iex> [{:some, 1}, :none, {:some, 3}]
      ...> |> OptionEx.flatten_enum()
      :none

      iex> %{a: {:some, 1}, b: {:some, 2}, c: {:some, 3}}
      ...> |> OptionEx.flatten_enum()
      {:some, %{a: 1, b: 2, c: 3}}

      iex> %{a: {:some, 1}, b: :none, c: {:some, 3}}
      ...> |> OptionEx.flatten_enum()
      :none

  """
  @spec flatten_enum(Enum.t()) :: t
  def flatten_enum(%{} = enum) do
    Enum.reduce(enum, {:some, %{}}, fn
      {key, {:some, value}}, {:some, result} ->
        Map.put(result, key, value)
        |> return

      _, :none ->
        :none

      {_, :none}, _ ->
        :none
    end)
  end

  def flatten_enum(enum) when is_list(enum) do
    Enum.reduce(enum, {:some, []}, fn
      {:some, value}, {:some, result} ->
        {:some, [value | result]}

      _, :none ->
        :none

      :none, _ ->
        :none
    end)
    |> map(&Enum.reverse/1)
  end

  def flatten_enum(_), do: :none

  @doc """
  Converts an `t:Option.t/0` to a result type.

  ## Examples

      iex> OptionEx.to_result({:some, 5})
      {:ok, 5}
      ...> OptionEx.to_result(:none)
      {:error, "OptionEx.to_result: The option was empty"}

  """
  @spec to_result(t) :: {:ok, term} | {:error, String.t()}
  def to_result({:some, value}), do: {:ok, value}

  def to_result(:none), do: {:error, "OptionEx.to_result: The option was empty"}

  @doc """
  Converts an `t:Option.t/0` to a Result type, specifying the error reason in case the `t:Option.t/0` is empty.
  The Result type consists of an {:ok, term} tuple, or an {:error, term} tuple.

  ## Examples

      iex> OptionEx.to_result({:some, 5}, :unexpected_empty_value)
      {:ok, 5}
      ...> OptionEx.to_result(:none, :unexpected_empty_value)
      {:error, :unexpected_empty_value}

  """
  @spec to_result(t, term) :: {:ok, term} | {:error, term}
  def to_result({:some, value}, _), do: {:ok, value}

  def to_result(:none, reason), do: {:error, reason}

  @doc """
  Converts an `t:Option.t/0` to a bool, ignoring the inner value.

  ## Examples

      iex> OptionEx.to_bool({:some, 5})
      true
      ...> OptionEx.to_bool(:none)
      false

  """
  @spec to_bool(t) :: boolean
  def to_bool({:some, _}), do: true

  def to_bool(:none), do: false

  @spec curry(fun, term) :: term
  defp curry(fun, arg1), do: apply_curry(fun, [arg1])

  @spec apply_curry(fun, [term]) :: term
  defp apply_curry(fun, args) do
    {_, arity} = :erlang.fun_info(fun, :arity)

    if arity == length(args) do
      apply(fun, Enum.reverse(args))
    else
      fn arg -> apply_curry(fun, [arg | args]) end
    end
  end
end
