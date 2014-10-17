FactoryGirl.define do
  factory :student do
    klass nil
    section nil
    user
    level "graded"
    has_dropped false
    student_custom_identifier { SecureRandom.hex(6) }
    educator_custom_identifier { SecureRandom.hex(6) }
    random_education_identifier { SecureRandom.hex(6) }

    trait :graded do
      level "graded"
    end

    trait :auditing do
      level "auditing"
    end

    trait :dropped do
      has_dropped true 
    end

    after(:build) do |student|
      # section and klass need to agree
      student.klass ||= student.section.try(:klass) || FactoryGirl.build(:klass)
    end

  end
end
