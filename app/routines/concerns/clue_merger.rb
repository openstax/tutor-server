module ClueMerger
  def merge_clues(book_containers, clue_by_book_container_uuid)
    weights_by_book_container_uuids = Hash.new { |hash, key| hash[key] = 0 }
    book_containers.each do |bc|
      (bc[:unmapped_tutor_uuids] || [ bc[:tutor_uuid] ]).each do |book_container_uuid|
        weights_by_book_container_uuids[book_container_uuid] += bc[:num_completed_exercises]
      end
    end
    is_real = false
    weights_by_clues = {}
    weights_by_book_container_uuids.each do |book_container_uuid, weight|
      clue = clue_by_book_container_uuid[book_container_uuid]
      is_real = true if clue[:is_real]
      weights_by_clues[clue] = weight
    end
    weights_by_clues = weights_by_clues.select { |clue, weight| clue[:is_real] } if is_real
    total_weight = weights_by_clues.values.sum
    most_likely = if total_weight == 0
      0.5
    else
      weights_by_clues.map { |clue, weight| clue[:most_likely] * weight }.sum/total_weight
    end

    # We could probably do something fancier to combine the confidence intervals,
    # but we do not currently use them anywhere
    clues = weights_by_clues.keys
    {
      minimum: clues.map { |clue| clue[:minimum] }.min,
      most_likely: most_likely,
      maximum: clues.map { |clue| clue[:maximum] }.max,
      is_real: is_real
    }
  end
end
