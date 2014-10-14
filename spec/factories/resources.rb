FactoryGirl.define do
  sequence :url do |n| "http://www.#{n}.com" end

  factory :resource do
    ignore do
      a_url { generate(:url) }
    end

    url { "#{a_url}" }
    is_immutable false
    content { "Content from #{a_url}" }
  end
end
