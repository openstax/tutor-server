FactoryBot.define do
  factory :short_code_short_code, class: '::ShortCode::Models::ShortCode' do
    code { SecureRandom.hex(4) }
  end
end
