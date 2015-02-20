class OpenStax::Exercises::V1::FakeClient

  #
  # Api wrappers
  #

  def exercises(options={})
    arrayify(options, :number)
    arrayify(options, :version)
    arrayify(options, :id)
    arrayify(options, :tag)

    match_sets = []

    match_sets.push( @exercises_array.select{|ee| options[:id].include?(ee[:id])}           ) if options[:id]
    match_sets.push( @exercises_array.select{|ee| (options[:tag] & ee[:tags]).any?}         ) if options[:tag]
    match_sets.push( @exercises_array.select{|ee| options[:number].include?(ee[:number])}   ) if options[:number]
    match_sets.push( @exercises_array.select{|ee| options[:version].include?(ee[:version])} ) if options[:version] 

    result = nil

    match_sets.each do |match_set|
      if result.nil?
        result = match_set
      else
        result = result & match_set
      end
    end

    (result || []).collect{|exercise| exercise[:content]}.to_json
  end

  #
  # Methods to help fake the fake content
  #

  def add_exercise(options={})
    exercise_number = next_exercise_number

    options[:number] ||= exercise_number
    options[:content] ||= new_exercise_hash(options[:number])
    options[:tags] ||= []
    options[:version] ||= 1
    options[:id] ||= "e#{options[:number]}v#{options[:version]}"

    @exercises_array.push(
      {
        content: options[:content],
        tags: options[:tags],
        number: options[:number],
        version: options[:version],
        id: options[:id]
      }
    )
  end

  def reset!
    @exercises_array = []
    @uid = 0
    @exercise_number = 0
  end

  attr_reader :exercises_array

  def initialize
    reset!
  end

  def new_exercise_hash(exercise_number = next_exercise_number)
    {
      stimulus_html: "This is fake exercise #{exercise_number}. <span data-math='\\dfrac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}'></span>",
      questions: [
        {
          id: "#{next_uid}",
          format: "multiple-choice",
          stem_html: "Select 10 N.",
          answers:[
            { id: "#{next_uid}", content_html: "10 N",
              correctness: 1.0, feedback_html: "Right!" },
            { id: "#{next_uid}", content_html: "1 N",
              correctness: 0.0, feedback_html: "Wrong!" }
          ]
        }
      ]
    }
  end

  private

  def next_uid
    @uid += 1
  end

  def next_exercise_number
    @exercise_number += 1
  end

  # Makes the value of hash[:key] an array if isn't already one and the key exists
  def arrayify(hash, key)
    hash[key] = [hash[key]].flatten if hash[key]
  end

end