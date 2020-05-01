FactoryBot.define do
  factory :cache_period_book_part, class: '::Cache::PeriodBookPart' do
    association :period, factory: :course_membership_period

    book_part_uuid { SecureRandom.uuid }
    is_page { [ true, false ].sample }
    clue do
      {
        minimum: 0.0,
        most_likely: 0.5,
        maximum: 1.0,
        is_real: false
      }
    end
  end
end
