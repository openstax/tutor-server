class OpenStax::Exercises::V1::FakeClient
  STANDARD_TAGS = [
    [ 'type:practice', 'k12phys', 'apbio', 'os-practice-problems' ],
    [ 'type:conceptual-or-recall', 'k12phys', 'apbio', 'os-practice-concepts' ]
  ]

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
    tags = [params[:tag]].compact.flatten
    return { total_count: 0, items: [] }.stringify_keys if tags.blank?

    book_location_by_tag = Content::Models::Page.joins(
      :tags
    ).where(tags: { value: tags }).pluck(:value, :book_location).to_h

    results = tags.flat_map do |tag|
      store.fetch("fake/exercises/tag/#{tag}") do
        next [] if book_location_by_tag[tag].blank?

        STANDARD_TAGS.each_with_index.map do |standard_tags, index|
          self.class.new_exercise_hash number: -index-1, tags: standard_tags + [ tag ]
        end
      end
    end

    { total_count: results.size, items: results }.deep_stringify_keys
  end

  #
  # Methods to help fake the fake content
  #
  def self.new_exercise_hash(uuid: SecureRandom.uuid, group_uuid: SecureRandom.uuid,
                             number: -1, version: 1, uid: nil, tags: nil, num_questions: 1)
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
      questions: num_questions.times.map do |index|
        question_number = (number || -1) + index

        {
          id: "#{question_number}",
          formats: ["multiple-choice", "free-response"],
          stem_html: "Select 10 N. (#{index})",
          answers: [
            { id: "#{2*question_number + 1}", content_html: "10 N",
              correctness: 1.0, feedback_html: "Right!" },
            { id: "#{2*question_number}", content_html: "1 N",
              correctness: 0.0, feedback_html: "Wrong!" }
          ],
          solutions: [ { content_html: "The first one." } ]
        }
      end
    }
  end
end
