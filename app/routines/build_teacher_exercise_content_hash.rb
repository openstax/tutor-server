class BuildTeacherExerciseContentHash
  lev_routine

  TIMES = ['short', 'medium', 'long']
  DIFFICULTIES = ['easy', 'medium', 'difficult']
  BLOOMS = [1, 2, 3, 4, 5, 6]
  DOKS = [1, 2, 3, 4]

  protected

  def exec(data:)
    content_hash = {}

    content_hash[:tags] = [].tap do |tags|
      tags << "time:#{data[:tagTime].value}" if TIMES.include? data[:tagTime].value
      tags << "difficulty:#{data[:tagDifficulty].value}" if DIFFICULTIES.include? data[:tagDifficulty].value
      tags << "blooms:#{data[:tagBloom].value}" if BLOOMS.include? data[:tagBloom].value
      tags << "dok:#{data[:tagDok].value}" if DOKS.include? data[:tagDok].value
    end

    content_hash[:questions] = [{
      is_answer_order_important: true,
      stimulus_html: "",
      stem_html: data[:questionText],
      answers: data[:options].map do |option|
        {
          content_html: option[:content],
          correctness: option[:correctness],
          feedback_html: option[:feedback]
        }
      end
      hints: [],
      formats: ["free-response", "multiple-choice"],
    }]

    # Extraneous fields
    content_hash.merge({
      derived_from: [],
      is_vocab: false,
      authors: [],
      uuid: "",
      group_uuid: ""
    })

    outputs.content_hash = content_hash
  end
end
