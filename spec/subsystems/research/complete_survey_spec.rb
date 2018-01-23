require 'rails_helper'

RSpec.describe Research::CompleteSurvey do

  let(:survey)    { FactoryBot.create(:research_survey) }

  it 'records the response and sets the survey as completed' do
    described_class[survey: survey, response: { test: true, favorite_color: 'red'}]

    expect(survey.completed_at).to be_between(Time.now - 10.second, Time.now)
    expect(survey.survey_js_response).to eq('test' => true, 'favorite_color' => 'red')
  end

  it 'sets error when survey is hidden' do
    survey.update_attributes!(hidden_at: Time.now)
    result = described_class.call(survey: survey, response: :bad_value!)
    expect(result.errors).not_to be_empty
    expect(result.errors.first.message).to include('survey is hidden')
  end

end
