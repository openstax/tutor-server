require 'rails_helper'

RSpec.describe 'research/survey_plans/index', type: :view do
  before(:all) { @survey_plan = FactoryBot.create :research_survey_plan }

  before { assign :survey_plans, survey_plans }

  context 'when there are no survey_plans' do
    let(:survey_plans) { [] }

    it 'does not explode' do
      expect { render }.not_to raise_error

      expect(rendered).not_to be_blank
    end
  end

  context 'when there are survey_plans' do
    let(:survey_plans) { [ @survey_plan ] }

    it 'does not explode' do
      expect { render }.not_to raise_error

      expect(rendered).not_to be_blank
    end
  end
end
