class Api::V1::ResearchSurveysController < Api::V1::ApiController

  api :PUT, '/research_surveys/:id', 'Submit response to research survey'
  description <<-EOS
    Saves the student's responses to a survey.
  EOS
  def update
    OSU::AccessPolicy.require_action_allowed!(:complete, current_api_user, survey)
    result = Research::CompleteSurvey.call(
      survey: survey, **consumed(Api::V1::ResearchSurveyRepresenter)
    )
    if result.errors.any?
      render_api_errors(result.errors)
    else
      head :no_content
    end
  end


  protected

  def survey
    @survey ||= Research::Models::Survey.find(params[:id])
  end

end
