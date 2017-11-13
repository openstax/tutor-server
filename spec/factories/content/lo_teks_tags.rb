FactoryBot.define do
  factory :content_lo_teks_tag, class: ::Content::Models::LoTeksTag do
    association :lo, factory: :content_tag
    association :teks, factory: :content_tag
  end
end
