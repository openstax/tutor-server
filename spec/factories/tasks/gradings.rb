FactoryBot.define do
  factory :tasks_grading, class: 'Tasks::Models::Grading' do
    association :tasked_exercise, factory: :tasks_tasked_exercise

    points   { 1.0 }
    comments { ''  }
  end
end
