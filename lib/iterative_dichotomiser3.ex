defmodule IterativeDichotomiser3 do
  @moduledoc """
  Documentation for `IterativeDichotomiser3`.
  """

  @type classifier(class) :: (map() -> class)
  @type tree(class) :: {:node, attribute :: term(), %{term() => tree(class)}} | {:leaf, class}

  @spec decision_tree([map()], [attribute], classifier(class)) ::
          {:ok, tree(class)} | {:error, term()}
        when attribute: term(), class: term()
  def decision_tree(samples, attributes, classifier)

  def decision_tree([], _attributes, _classifier) do
    {:error, :no_samples}
  end

  def decision_tree(samples, attributes, classifier) do
    {:ok, build_decision_tree(samples, attributes, classifier)}
  end

  defp build_decision_tree(samples, [], classifier) do
    {class, _class_samples} =
      samples
      |> Enum.group_by(classifier)
      |> Enum.max_by(fn {class, class_samples} ->
        length(class_samples)
      end)

    {:leaf, class}
  end

  defp build_decision_tree(samples, attributes, classifier) do
    n_samples = length(samples)

    case Enum.uniq_by(samples, classifier) do
      [single_class] ->
        {:leaf, classifier.(single_class)}

      _more_than_one ->
        {optimal_attribute, grouping} =
          attributes
          |> Stream.map(fn attribute ->
            {attribute, Enum.group_by(samples, &Map.get(&1, attribute))}
          end)
          |> Enum.min_by(fn {attribute, grouping} ->
            grouping
            |> Enum.map(fn {attribute_value, attribute_samples} ->
              length(attribute_samples) / n_samples * entropy(attribute_samples, classifier)
            end)
            |> Enum.sum()
          end)

        {:node, optimal_attribute,
         Map.new(
           grouping,
           fn {value, value_samples} ->
             {value,
              build_decision_tree(
                value_samples,
                List.delete(attributes, optimal_attribute),
                classifier
              )}
           end
         )}
    end
  end

  def classify(sample, tree)

  def classify(_sample, {:leaf, class}) do
    {:ok, class}
  end

  def classify(sample, {:node, attribute, groupings}) do
    value = Map.get(sample, attribute)

    case Map.fetch(groupings, value) do
      {:ok, tree} ->
        classify(sample, tree)

      :error ->
        :error
    end
  end

  @spec entropy([map()], classifier(class)) :: float() when class: term()
  def entropy(samples, classifier) do
    n_samples = length(samples)

    samples
    |> Enum.group_by(classifier)
    |> Enum.map(fn {class, class_samples} ->
      p_class = length(class_samples) / n_samples

      -p_class * :math.log2(p_class)
    end)
    |> Enum.sum()
  end
end
