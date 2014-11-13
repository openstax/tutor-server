module BigLearn

  mattr_accessor :use_stubs
  self.use_stubs = false

  # TODO ponder how to make this call (and other 3rd party calls) in the background in a standard 
  # TaskStep-friendly way

  def self.projection_next_questions(allowed_exercise_definitions:, learner:, count:, difficulty: 0.5)
    if use_stubs
      allowed_exercise_definitions.shuffle[0..count-1]
    else
      url = ['http://api1.biglearn.openstax.org/projections/next_questions?',
             allowed_exercise_definitions.collect{|ed| "question=#{/(\d+)$/.match(ed.url)[0]}&"},
             "questionCount=#{count}&",
             "learner=#{learner}&",
             "desiredDifficulty=#{difficulty}"].join("")

      # If this sticks around as a manual construction of a query, use Hash.to_query or cousin
      
      response = HTTParty.get(url)

      ids = response.parsed_response["questionTopics"].collect{|qt| qt["question"]}
      allowed_exercise_definitions.select{|ed| ids.include?(/(\d+)$/.match(ed.url)[0]) }
    end
  end

end