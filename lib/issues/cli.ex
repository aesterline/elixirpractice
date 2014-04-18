defmodule Issues.CLI do
  @default_count 4

  def run(argv) do
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
      |> convert_to_list_of_hashdicts
      |> sort_into_ascending_order
      |> Enum.take(count)
  end

  def decode_response({:ok, body}), do: Jsonex.decode(body)
  def decode_response({:error, msg}) do
    error = Jsonex.decode(msg)["message"]
    IO.puts "Error fetching from Github: #{error}"
    System.halt(2)
  end

  def convert_to_list_of_hashdicts(list) do
    list |> Enum.map(&HashDict.new/1)
  end

  def sort_into_ascending_order(list_of_issues) do
    Enum.sort list_of_issues,
         fn il, i2 -> il["created_at"] <= i2["created_at"] end
  end
end