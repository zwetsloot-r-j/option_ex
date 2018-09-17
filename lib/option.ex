defmodule Option do
  @moduledoc """
  Library containing helper functions for the option monad.
  """

  @type t ::
          {:some, term}
          | :none

  @doc """
  Elevates a value to an Option type.
  If nil is passed, an empty Option will be returned.

  ## Examples

      iex> Option.return(1)
      {:some, 1}

      iex> Option.return(nil)
      :none

  """
  @spec return(term) :: t
  def return(nil), do: :none

  def return(value), do: {:some, value}

  @doc """
  Runs a function against the Option value.

  ## Examples

      iex> option = {:some, 1}
      ...> Option.map(option, &(&1 + 1))
      {:some, 2}

      iex> option = :none
      ...> Option.map(option, &(&1 + 1))
      :none 

  """
  @spec map(t, fun) :: t
  def map({:some, value}, fun) do
    {:some, fun.(value)}
  end

  def map(:none, _), do: :none

  @doc """
  Executes or partially executes the function given as value of the first Option,
  and applies it with the value of the second Option.
  If the function has an arity greater than 1, the returned Option value will be the function partially applied.

  ## Examples

      iex> value_option = {:some, 1}
      ...> function_option = {:some, fn value -> value + 1 end}
      ...> Option.appl(function_option, value_option)
      {:some, 2}

      iex> {:some, fn value1, value2, value3 -> value1 + value2 + value3 end}
      ...> |> Option.appl({:some, 1})
      ...> |> Option.appl({:some, 2})
      ...> |> Option.appl({:some, 3})
      {:some, 6}

      iex> :none
      ...> |> Option.appl({:some, 1})
      ...> |> Option.appl({:some, 1})
      ...> |> Option.appl({:some, 1})
      :none

      iex> {:some, fn value1, value2, value3 -> value1 + value2 + value3 end}
      ...> |> Option.appl({:some, 1})
      ...> |> Option.appl({:some, 1})
      ...> |> Option.appl(:none)
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
  Applies a function with the value of the Option.
  The passed function is expected to return an Option.
  This can be useful for chaining functions that elevate values into options together.

  ## Examples

      iex> head = fn
      ...>   [] -> :none
      ...>   list -> {:some, hd(list)}
      ...> end
      ...> head.([[4]])
      ...> |> Option.bind(head)
      {:some, 4}

      iex> head = fn
      ...>   [] -> :none
      ...>   list -> {:some, hd(list)}
      ...> end
      ...> head.([[]])
      ...> |> Option.bind(head)
      :none

  """
  @spec bind(t, (term -> t)) :: t
  def bind({:some, value}, fun) do
    fun.(value)
  end

  def bind(:none, _), do: :none

  @doc """
  Unwraps the Option to return its value.
  Throws an error if the Option is :none.

  ## Examples

      iex> Option.return(5)
      ...> |> Option.unwrap!()
      5

  """
  @spec unwrap!(t) :: term
  def unwrap!({:some, value}), do: value

  def unwrap!(:none), do: throw("Option.unwrap!: The option has no value")

  @doc """
  Unwraps the Option to return its value.
  The second argument will be a specific error message to throw when the Option is empty.

  ## Examples

      iex> Option.return(5)
      ...> |> Option.expect!("The value was not what was expected")
      5

  """
  @spec expect!(t, String.t()) :: term
  def expect!({:some, value}, _), do: value

  def expect!(_, message), do: throw(message)

  @doc """
  Unwraps the Option to return its value.
  If the Option is empty, it will return the default value passed as second argument instead.

  ## Examples

      iex> Option.return(5)
      ...> |> Option.or_else(4)
      5

      iex> :none
      ...> |> Option.or_else(4)
      4

  """
  @spec or_else(t, term) :: term
  def or_else({:some, value}, _), do: value

  def or_else(_, default), do: default

  @doc """
  Unwraps the Option to return its value.
  If the Option is empty, the given function will be applied instead.

  ## Examples

      iex> Option.return(5)
      ...> |> Option.or_else_with(fn -> 4 end)
      5

      iex> :none
      ...> |> Option.or_else_with(fn -> 4 end)
      4

  """
  @spec or_else_with(t, fun) :: term
  def or_else_with({:some, value}, _), do: value

  def or_else_with(:none, fun), do: fun.()

  @doc """
  Flatten nested Options into one Option.

  ## Examples

      iex> Option.return(5)
      ...> |> Option.return()
      ...> |> Option.return()
      ...> |> Option.flatten()
      {:some, 5}

      iex> {:some, {:some, :none}}
      ...> |> Option.flatten()
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
  Flattens an enumerable of Options into an Option of enumerables.

  ## Examples

      iex> [{:some, 1}, {:some, 2}, {:some, 3}]
      ...> |> Option.flatten_enum()
      {:some, [1, 2, 3]}

      iex> [{:some, 1}, :none, {:some, 3}]
      ...> |> Option.flatten_enum()
      :none

      iex> %{a: {:some, 1}, b: {:some, 2}, c: {:some, 3}}
      ...> |> Option.flatten_enum()
      {:some, %{a: 1, b: 2, c: 3}}

      iex> %{a: {:some, 1}, b: :none, c: {:some, 3}}
      ...> |> Option.flatten_enum()
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

  @spec to_result(t) :: {:ok, term} | {:error, term}
  def to_result({:some, value}), do: {:ok, value}

  def to_result(:none), do: {:error, "Option.to_result: The option was empty"}

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
