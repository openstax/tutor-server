class Content::Models::ExerciseVisitor < Content::Models::BookVisitor

  def initialize
    @exercises = {}
  end

  def visit_page(page)
    page_tags = page.page_tags.collect{|pt| pt.tag}.flatten
    page_tag_ids = page_tags.collect{|t| t.id}

    page_exercises =
      Content::Models::Exercise.joins{exercise_tags.tag}
                       .where{exercise_tags.content_tag_id.in page_tag_ids}

    page_exercises.each do |page_exercise|
      wrapper = OpenStax::Exercises::V1::Exercise.new(page_exercise.content)

      exercise_lo_names = wrapper.los

      (@exercises[wrapper.uid] ||= {}).tap do |entry|
        entry['uid']  = wrapper.uid
        entry['id']   = page_exercise.id
        entry['url']  = wrapper.url
        entry['los'] = ((entry['los'] || []) + exercise_lo_names).uniq
        entry['tags'] = (((entry['tags'] || []) + wrapper.tags) - entry['los']).uniq
      end
    end
  end

  def output
    @exercises
  end

end
