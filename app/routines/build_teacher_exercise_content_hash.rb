class BuildTeacherExerciseContentHash
  lev_routine

  TIMES = { tag: 'time', key: 'tagTime', values: ['short', 'medium', 'long'] }
  DIFFICULTIES = { tag: 'difficulty', key: 'tagDifficulty', values: ['easy', 'medium', 'difficult'] }
  BLOOMS = { tag: 'blooms', key: 'tagBloom', values: ['1', '2', '3', '4', '5', '6'] }
  DOKS = { tag: 'dok', key: 'tagDok', values: ['1', '2', '3', '4'] }

  protected

  def exec(data:)
    content_hash = {}

    content_hash[:tags] = [TIMES, DIFFICULTIES, BLOOMS, DOKS].map do |tag|
      value = data.dig(tag[:key], 'value')
      "#{tag[:tag]}:#{value}" if tag[:values].include? value
    end
    content_hash[:tags].compact!

     question = {
      is_answer_order_important: true,
      stimulus_html: "",
      stem_html: data[:questionText],
      title: data[:questionName],
      collaborator_solutions: []
    }

    question[:answers] = (data[:options] || []).map do |option|
      {
        content_html: option[:content],
        correctness: option[:correctness],
        feedback_html: option[:feedback]
      }
    end

    if data[:detailedSolution]
      question[:collaborator_solutions] << {
        attachments: [],
        solution_type: 'detailed',
        content_html: data[:detailedSolution]
      }
    end

    content_hash[:formats] = [].tap do |formats|
      formats << "free-response" if data[:isTwoStep] || question[:answers].empty?
      formats << "multiple-choice" if question[:answers].any?
    end

    content_hash[:questions] = [question]

    # Extraneous fields
    content_hash.merge({
      derived_from: [],
      is_vocab: false,
      hints: [],
      authors: [],
      uuid: "",
      group_uuid: ""
    })

    outputs.content_hash = content_hash
  end
end
