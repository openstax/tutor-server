require 'rails_helper'

RSpec.describe Research::Models::Study, type: :model do
  subject(:study) { FactoryBot.create :research_study }

  it { is_expected.to have_many(:survey_plans) }
  it { is_expected.to have_many(:study_courses) }
  it { is_expected.to have_many(:courses) }
  it { is_expected.to have_many(:cohorts) }

  it { is_expected.to validate_presence_of(:name) }
end
