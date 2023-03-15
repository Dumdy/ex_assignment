defmodule ExAssignment.Todos do
  @moduledoc """
  Provides operations for working with todos.
  """

  import Ecto.Query, warn: false
  alias ExAssignment.Repo

  alias ExAssignment.Todos.Todo

  @doc """
  Returns the list of todos, optionally filtered by the given type.

  ## Examples

      iex> list_todos(:open)
      [%Todo{}, ...]

      iex> list_todos(:done)
      [%Todo{}, ...]

      iex> list_todos()
      [%Todo{}, ...]

  """
  def list_todos(type \\ nil) do
    cond do
      type == :open ->
        from(t in Todo, where: not t.done, order_by: t.priority)
        |> Repo.all()

      type == :done ->
        from(t in Todo, where: t.done, order_by: t.priority)
        |> Repo.all()

      true ->
        from(t in Todo, order_by: t.priority)
        |> Repo.all()
    end
  end

  @doc """

  Returns a recommended todo item from a list of todos, based on each todo's priority score.

  Example:
  iex> todos =  [%Todo{priority: 2}, %Todo{priority: 5} ]
  iex> get_recommended(todos)
  %Todo{priority: 2}

  The `get_recommended/1` function calculates an urgency score for each todo item in the input list based on its priority value.
  It then calculates a probability score for each todo item based on its urgency score relative to the other todo items in the list.
  The function randomly selects a todo item from the list based on its probability score, and returns the recommended todo item.
  If multiple todo items have the same highest probability score, the function chooses one of them randomly.
  The function assumes that the `priority` field of each todo item is a non-negative integer.
  """
  def get_recommended(todos) do
    # Calculate urgency score for each todo based on its priority
    priority_values = Enum.map(todos, & &1.priority)
    max_priority = Enum.max(priority_values)
    min_priority = Enum.min(priority_values)

    urgency_scores =
      todos
      |> Enum.map(fn todo ->
        priority_ratio = (max_priority - todo.priority + 1) / (max_priority - min_priority + 1)

        {todo, priority_ratio}
      end)

    # Calculate probability for each todo
    sum_scores = Enum.reduce(urgency_scores, 0, fn {_, score}, acc -> acc + score end)

    probabilities = Enum.map(urgency_scores, fn {todo, score} -> {todo, score / sum_scores} end)

    # Randomly select a todo based on its probability
    random_prob = :rand.uniform()

    {recommended, _} =
      probabilities
      # Sort by decreasing probability
      |> Enum.sort_by(fn {_, prob} -> -prob end)
      |> Enum.find(fn {_, prob} -> random_prob <= prob end) || Enum.at(probabilities, 0)

    recommended
  end

  @doc """
  Gets a single todo.

  Raises `Ecto.NoResultsError` if the Todo does not exist.

  ## Examples

      iex> get_todo!(123)
      %Todo{}

      iex> get_todo!(456)
      ** (Ecto.NoResultsError)

  """
  def get_todo!(id), do: Repo.get!(Todo, id)

  @doc """
  Creates a todo.

  ## Examples

      iex> create_todo(%{field: value})
      {:ok, %Todo{}}

      iex> create_todo(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_todo(attrs \\ %{}) do
    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a todo.

  ## Examples

      iex> update_todo(todo, %{field: new_value})
      {:ok, %Todo{}}

      iex> update_todo(todo, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a todo.

  ## Examples

      iex> delete_todo(todo)
      {:ok, %Todo{}}

      iex> delete_todo(todo)
      {:error, %Ecto.Changeset{}}

  """
  def delete_todo(%Todo{} = todo) do
    Repo.delete(todo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo changes.

  ## Examples

      iex> change_todo(todo)
      %Ecto.Changeset{data: %Todo{}}

  """
  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end

  @doc """
  Marks the todo referenced by the given id as checked (done).

  ## Examples

      iex> check(1)
      :ok

  """
  def check(id) do
    {_, _} =
      from(t in Todo, where: t.id == ^id, update: [set: [done: true]])
      |> Repo.update_all([])

    :ok
  end

  @doc """
  Marks the todo referenced by the given id as unchecked (not done).

  ## Examples

      iex> uncheck(1)
      :ok

  """
  def uncheck(id) do
    {_, _} =
      from(t in Todo, where: t.id == ^id, update: [set: [done: false]])
      |> Repo.update_all([])

    :ok
  end
end
