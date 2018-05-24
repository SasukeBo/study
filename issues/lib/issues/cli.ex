defmodule Issues.CLI do
  import Issues.TableFormatter, only: [print_table_for_columns: 2]
  @default_count 4

  @moduledoc """
  Handle the command line parsing and the dispatch to
  the various functions that end up generating
  a table of the last _n_ issues in a github project
  """

  # def run(argv) do
  #   parse_args(argv)
  # end

  def run(argv) do
    argv
      |> parse_args
      |> process
  end

  @doc """
  `argv` can be -h or --help, which returns :help.
  Otherwise it is a github user name, project name, and (optionally)
  the number of entries to format.
  Return a tuple of `{ user, project, count }`, or `:help` if help was given.
  """

  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: [help: :boolean], aliases: [h: :help])

    case parse do
      {[help: true], _, _} ->
        :help

      {_, [user, project, count], _} ->
        {user, project,
          if is_binary(count) do
            String.to_integer(count)
          else
            count
          end
        }

      {_, [user, project], _} ->
        {user, project, @default_count}

      _ ->
        :help
    end
  end

  def process(:help) do
    IO.puts """
    usage: issues <user> <project> [count | #{@default_count}]
    """
    System.halt(0)
  end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> decode_response
    |> convert_to_list_of_maps
    |> sort_into_ascending_order
    |> Enum.take(count)
    |> print_table_for_columns(["number", "created_at", "title"])
  end

  def decode_response({:ok, body}), do: body

  def decode_response({:error, error}) do
    {_, message} = List.keyfind(error, "message", 0)
    IO.puts "Error fetching from Github: #{message}"
    System.halt(2)
  end

  def convert_to_list_of_maps(list) do
    list
    |> Enum.map(&Enum.into(&1, Map.new))
  end

  def sort_into_ascending_order(list_of_issues) do
    Enum.sort list_of_issues,
      fn i1, i2 -> i1["created_at"] <= i2["created_at"] end
  end

  # 现在使用书本教程的函数来处理数据，先注释掉我自己写的函数以免混乱
  # def print_table_for_columns(result, columns \\ ["number", "created_at", "title"]) do
  #   for issue <- result do
  #     values = fetch_column_value(issue, columns)
  #     for value <- values, do: IO.puts value
  #   end
  # end

  # defp fetch_column_value(issue, columns) do
  #   for head <- columns do
  #     issue[head]
  #   end
  # end
end