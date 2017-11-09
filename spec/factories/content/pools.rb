FactoryBot.define do
  factory :content_pool, class: '::Content::Models::Pool' do
    association :ecosystem, factory: :content_ecosystem
    uuid { SecureRandom.uuid }
    pool_type { Content::Models::Pool.pool_types.values.sample }
  end
end
