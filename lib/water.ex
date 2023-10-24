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

  def get_ids do
    case HTTPoison.get(@ids_url) do
      {:ok, %{status_code: 200, body: body}} ->
        [returnField | values] = List.flatten(Jason.decode!(body))
        # IO.inspect(values)
        IO.puts("values contains #{length(values)} items.")
        # Store the values to a file
        File.write!("values.txt", Enum.join(values, "\n"))
        # Return the values
        {:ok, values}

      {:ok, %{status_code: code, body: _}} ->
        IO.puts("HTTP request failed with status code #{code}.")

      {:error, reason} ->
        IO.puts("HTTP request failed with reason: #{inspect(reason)}")
    end
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

  def get_values do
    case get_ids() do
      {:ok, [id | values]} ->
        fetch_data_for_ids([id | values])

      {:error, reason} ->
        IO.puts("Failed to fetch IDs: #{reason}")
    end
  end
end
