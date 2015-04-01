class Content::Models::ExerciseVisitor < Content::Models::BookVisitor

  def initialize
    @exercises = {}
  end

  def visit_page(page)
    page_exercises = Content::Models::Exercise
      .joins{exercise_tags.tag.page_tags}
      .where{exercise_tags.tag.page_tags.content_page_id == my{page.id}}

    page_exercises.each do |page_exercise|
      wrapper = OpenStax::Exercises::V1::Exercise.new(page_exercise.content)

      (@exercises[wrapper.uid] ||= {}).tap do |entry|
        entry['uid']  = wrapper.uid
        entry['id']   = page_exercise.id
        entry['url']  = wrapper.url
        entry['los']  = ((entry['los'] || []) + wrapper.los).uniq
        entry['tags'] = (((entry['tags'] || []) + wrapper.tags) - entry['los']).uniq
      end
    end
  end

  def output
    @exercises
  end

end
