class Content::ExerciseVisitor < Content::BookVisitor

  def initialize
    @exercises = {}
  end

  def visit_page(page)
    page_topics = page.page_topics.collect{|pt| pt.topic}.flatten
    page_topic_ids = page_topics.collect{|t| t.id}

    page_exercises = 
      Content::Exercise.joins{exercise_topics.topic}
                       .where{exercise_topics.content_topic_id.in page_topic_ids}

    page_exercises.each do |page_exercise|
      wrapper = OpenStax::Exercises::V1::Exercise.new(page_exercise.content)

      exercise_topic_names = 
        page_exercise.exercise_topics.collect{|et| et.topic.name}

      (@exercises[wrapper.uid] ||= {}).tap do |entry|
        entry['uid']  = wrapper.uid
        entry['id']   = page_exercise.id
        entry['url']  = wrapper.url
        entry['topics'] = ((entry['topics'] || []) + exercise_topic_names).uniq
        entry['tags'] = (((entry['tags'] || []) + wrapper.tags) - entry['topics']).uniq
      end
    end 
  end

  def output
    @exercises
  end

end