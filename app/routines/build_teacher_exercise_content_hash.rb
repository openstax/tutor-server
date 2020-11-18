class BuildTeacherExerciseContentHash
  lev_routine

  protected

  def exec(question:, answers:, tags: [])
    content_hash = {
      tags: tags
    }

    content_hash[:questions] = {
      is_answer_order_important: false,
      stimulus_html: "",
      stem_html: question,
      answers: answers.map do |answer|
        {
          content_html: answer[:content],
          correctness: answer[:correctness],
          feedback_html: answer[:feedback]
        }
      end
    }

    outputs.content_hash = content_hash
  end
end
