require 'rails_helper'

RSpec.describe Tasks::Models::PracticeQuestion, type: :model do
  subject(:practice_question) { FactoryBot.create :tasks_practice_question }

  it "factory creates records" do
    expect(subject).not_to be_new_record
  end
end
