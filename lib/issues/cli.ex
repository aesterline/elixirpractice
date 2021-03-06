defmodule Issues.CLI do
  import Issues.TableFormatter, only: [ print_table_for_columns: 2 ]
  
  @default_count 4

  def main(argv) do
    argv
      |> parse_args
      |> process
  end

  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: [ help: :boolean ],
                                     aliases:  [ h: :help ])

    case parse do
      { [ help: true ], _, _ } -> :help

      { _, [ user, project, count ], _ } -> { user, project, binary_to_integer(count) }

      { _, [ user, project ], _ } -> { user, project, @default_count }

      _ -> :help
    end
  end

  def process(:help) do
    IO.puts "usage: issues <user> <project> [ count | #{@default_count} ]"
  end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
      |> decode_response
      |> sort_into_ascending_order
      |> Enum.take(count)
      |> print_table_for_columns(["number", "created_at", "title"])
  end

  def decode_response({:ok, body}), do: JSON.decode(body)
  def decode_response({:error, msg}) do
    error = JSON.decode(msg)["message"]
    IO.puts "Error fetching from Github: #{error}"
    System.halt(2)
  end

  def sort_into_ascending_order({:ok, list_of_issues}) do
    Enum.sort list_of_issues,
         fn il, i2 -> il["created_at"] <= i2["created_at"] end
  end

  def sort_into_ascending_order({:error, msg}) do
    IO.puts "Error parsing response from Github: #{msg}"
    System.halt(2)
  end

end