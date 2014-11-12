

module BigLearn
  

  mattr_accessor :use_stubs
  self.use_stubs = false

  def self.projection_next_questions(allowed_exercise_definitions:, learner:, count:, difficulty: 0.5)
    if use_stubs
      allowed_exercise_definitions.shuffle[0..count-1]
    else
      url = ['http://api1.biglearn.openstax.org/projections/next_questions?',
             allowed_exercise_definitions.collect{|ed| "question=#{/(\d+)$/.match(ed.url)[0]}&"},
             "questionCount=#{count}&",
             "learner=#{learner}&",
             "desiredDifficulty=#{difficulty}"].join("")
      
      response = HTTParty.get(url)

      ids = response.parsed_response["questionTopics"].collect{|qt| qt["question"]}
      allowed_exercise_definitions.select{|ed| ids.include?(/(\d+)$/.match(ed.url)[0]) }
    end
  end



end