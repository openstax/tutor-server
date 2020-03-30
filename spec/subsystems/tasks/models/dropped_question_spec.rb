require 'rails_helper'

RSpec.describe Tasks::Models::DroppedQuestion, type: :model do
  subject(:dropped_question) { FactoryBot.create :tasks_dropped_question }

  it { is_expected.to belong_to :task_plan }

  it { is_expected.to validate_presence_of :question_id }
  it { is_expected.to validate_presence_of :drop_method }

  it do
    is_expected.to(
      validate_uniqueness_of(:question_id).scoped_to(:tasks_task_plan_id).case_insensitive
    )
  end
end
