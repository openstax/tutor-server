class OpenStax::Exercises::V1::FakeClient

  attr_reader :store

  def initialize(exercises_configuration)
    @store = exercises_configuration.fake_store
  end

  def reset!
    store.clear
  end

  def server_url
    "https://fake.exercises.client.openstax.org"
  end

  #
  # Api wrappers
  #

  def exercises(params = {}, options={})
    match_sets = params.map do |key, values|
      next if values.nil?

      store_keys = [values].flatten.map{ |value| "exercises/#{key}/#{value}" }
      match_json_array = store.read_multi(*store_keys).values
      match_hash_array = match_json_array.map{ |value| JSON.parse(value || '[]') }
      match_hash_array.flatten.uniq
    end.compact

    results = match_sets.reduce(:&) || []

    { 'total_count' => results.length, 'items' => results }
  end

  #
  # Methods to help fake the fake content
  #

  def add_exercise(options = {})
    options[:content] ||= self.class.new_exercise_hash(options)

    uuid = options[:content][:uuid]
    group_uuid = options[:content][:group_uuid]
    number = options[:content][:number]
    version = options[:content][:version]
    tags = options[:content][:tags]
    uid = options[:content][:uid]

    options[:content].tap do |content|
      store.write "exercises/uuid/#{uuid}", [content].to_json

      same_group_uuid_exercises = JSON.parse(store.read("exercises/uuid/#{group_uuid}") || '[]')
      store.write "exercises/uuid/#{group_uuid}",
                  (same_group_uuid_exercises + [content]).uniq.to_json

      same_number_exercises = JSON.parse(store.read("exercises/number/#{number}") || '[]')
      store.write "exercises/number/#{number}", (same_number_exercises + [content]).uniq.to_json

      same_version_exercises = JSON.parse(store.read("exercises/version/#{version}") || '[]')
      store.write "exercises/version/#{version}", (same_version_exercises + [content]).uniq.to_json

      store.write "exercises/id/#{uid}",  [content].to_json
      store.write "exercises/uid/#{uid}", [content].to_json

      tags.each do |tag|
        same_tag_exercises = JSON.parse(store.read("exercises/tag/#{tag}") || '[]')
        store.write "exercises/tag/#{tag}", (same_tag_exercises + [content]).uniq.to_json
      end
    end
  end

  def self.new_exercise_hash(uuid: SecureRandom.uuid, group_uuid: SecureRandom.uuid,
                             number: -1, version: 1, uid: nil, tags: nil, num_parts: 1)
    {
      uuid: uuid,
      group_uuid: group_uuid,
      number: number,
      version: version,
      uid: uid || "#{number}@#{version}",
      tags: tags || [],
      stimulus_html: "This is fake exercise #{number}. " +
                     "<span data-math='\\dfrac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}'></span>",
      attachments: [
        {
          id: "#{number}",
          asset: "https://somewhere.com/something.png"
        }
      ],
      questions: num_parts.times.map do |index|
        {
          id: "#{number}",
          formats: ["multiple-choice", "free-response"],
          stem_html: "Select 10 N. (#{index})",
          answers: [
            { id: "#{2*number + 1}", content_html: "10 N",
              correctness: 1.0, feedback_html: "Right!" },
            { id: "#{2*number}", content_html: "1 N",
              correctness: 0.0, feedback_html: "Wrong!" }
          ],
          solutions: [ { content_html: "The first one." } ]
        }
      end
    }
  end
end
