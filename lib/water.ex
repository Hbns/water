defmodule Water do
  @moduledoc """
  Documentation for `Water`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Water.hello()
      :world

  """
  @ids_url "https://hicws.vlaanderen.be/KiWIS/KiWIS?&type=queryServices&request=getTimeseriesList&datasource=4&format=json&timeseriesgroup_id=156163&returnfields=ts_id"

  # line 25 could store to disk to reduce requests..
  def get_ids do
    case HTTPoison.get(@ids_url) do
      {:ok, %{status_code: 200, body: body}} ->
        [_returnField | values] = List.flatten(Jason.decode!(body))
        # IO.inspect(values)
        IO.puts("values contains #{length(values)} items.")
        # Store the values to a file
        # File.write!("values.txt", Enum.join(values, "\n"))
        # Return the values
        {:ok, values}

      {:ok, %{status_code: code, body: _}} ->
        IO.puts("HTTP request failed with status code #{code}.")

      {:error, reason} ->
        IO.puts("HTTP request failed with reason: #{inspect(reason)}")
    end
  end

  # Step 1: Read the file into a string
  file_content = File.read!("winfo.txt")
  # Parse the outer JSON array
  parsed_json = Poison.decode!(file_content)

  # Now you have a list of JSON strings inside the outer array
  # Let's decode the inner JSON strings into maps
  json_maps =
    parsed_json
    |> Enum.map(&Poison.decode!(&1))

  # Now you have a list of JSON objects
  #IO.inspect(json_maps, pretty: true)


 # Let's say you want to find the object with ts_id "74184010"
ts_id_to_find = "74184010"

# Use Enum.find/2 to find the object with the specified ts_id
result = Enum.find(json_maps, fn map ->
  case hd(map) do
    %{"ts_id" => ts_id} when ts_id == ts_id_to_find -> true
    _ -> false
  end
end)

# If the object is found, 'result' will contain the map, otherwise, it will be nil
case result do
  nil ->
    IO.puts("Object with ts_id #{ts_id_to_find} not found.")
  map ->
    IO.inspect(map, pretty: true)
end

  # @level_url "https://hicws.vlaanderen.be/KiWIS/KiWIS?&type=queryServices&service=kisters&datasource=4&request=getTimeseriesValues&ts_id=#{id}!&metadata=true&format=&returnfields=Timestamp,Value,Quality%20Code"

  defp fetch_data_for_ids([]) do
    # Base case: When there are no more IDs to process, do nothing.
    :ok
  end

  defp fetch_data_for_ids([id | rest]) do
    url =
      "https://hicws.vlaanderen.be/KiWIS/KiWIS?&type=queryServices&service=kisters&datasource=4&request=getTimeseriesValues&ts_id=#{id}&metadata=true&format=json&returnfields=Timestamp,Value,Quality%20Code"

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        answer = Jason.decode!(body)
        data = answer["data"] |> hd()
        IO.inspect(data)

        # Recursively process the remaining IDs
        fetch_data_for_ids(rest)

      {:ok, %{status_code: code, body: _}} ->
        IO.puts("HTTP request failed with status code #{code}.")

      {:error, reason} ->
        IO.puts("HTTP request failed with reason: #{inspect(reason)}")
    end
  end

  # build the list of urls based in ids, helps JSONResponseDownloader
  defmodule URLBuilder do
    # Base case: empty list results in an empty URL list
    def make_url_list([]), do: []

    def make_url_list([id | rest]) do
      url =
        "https://hicws.vlaanderen.be/KiWIS/KiWIS?&type=queryServices&service=kisters&datasource=4&request=getTimeseriesValues&ts_id=#{id}&metadata=true&format=json&returnfields=Timestamp,Value,Quality%20Code"

      # Recursively build the URL list
      [url | make_url_list(rest)]
    end
  end

  # download all request into one file on disk.
  defmodule JSONResponseDownloader do
    def download_and_bundle_responses(urls, output_file) do
      responses = Enum.map(urls, &get(&1))
      File.write!(output_file, responses |> Poison.encode!(pretty: true))
    end

    defp get(url) do
      case HTTPoison.get(url) do
        {:ok, %{status_code: 200, body: body}} ->
          body

        {:ok, %{status_code: code, body: _}} ->
          IO.puts("HTTP request failed with status code #{code}.")

        {:error, reason} ->
          IO.puts("HTTP request failed with reason: #{inspect(reason)}")
      end
    end
  end

  # fetch to disk to reduce http requests when testing.
  def fetch_data_to_disk() do
    ids = get_values_fd()
    urls = URLBuilder.make_url_list(ids)
    JSONResponseDownloader.download_and_bundle_responses(urls, "winfo.txt")
  end

  defmodule FileReader do
    def read_file(filename) do
      File.stream!(filename)
      # Remove leading/trailing whitespace if needed
      |> Stream.map(&String.trim/1)
      |> Enum.to_list()
    end
  end

  # request via https
  def get_values do
    case get_ids() do
      {:ok, [id | values]} ->
        fetch_data_for_ids([id | values])

      {:error, reason} ->
        IO.puts("Failed to fetch IDs: #{reason}")
    end
  end

  # use the file on disk, reduce requests..
  def get_values_fd do
    filename = "ids.txt"
    result = FileReader.read_file(filename)
    # IO.inspect(result)
    result
  end
end
