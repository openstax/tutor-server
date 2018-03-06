class Research::SurveyPlansController < Research::BaseController

  respond_to :html

  before_filter :get_survey_plan, only: [:edit, :update, :preview, :publish, :hide, :export]

  def new
    @survey_plan = Research::Models::SurveyPlan.new
  end

  def create
    @survey_plan = Research::Models::SurveyPlan.new(cleared_params)

    if @survey_plan.save
      redirect_to research_survey_plans_path,
                  notice: 'Survey Plan was successfully created.'
    else
      render action: "new"
    end
  end

  def edit
  end

  def update
    if @survey_plan.update_attributes(cleared_params)
      redirect_to research_survey_plan_path(@survey_plan),
                  notice: 'Survey plan updated.'
    else
      render action: "edit"
    end
  end

  def preview
  end

  def publish
    begin
      Research::PublishSurveyPlan[survey_plan: @survey_plan]
      redirect_to research_survey_plans_path, notice: "Published survey plan #{@survey_plan.id}"
    rescue StandardError => ee
      redirect_to research_survey_plans_path, alert: "Could not publish survey plan #{@survey_plan.id}; #{ee.message}"
    end
  end

  def hide
    begin
      Research::HideSurveyPlan[survey_plan: @survey_plan]
      redirect_to research_survey_plans_path, notice: "Hid survey plan #{@survey_plan.id}"
    rescue StandardError => ee
      redirect_to research_survey_plans_path, alert: "Could not hide survey plan #{
                                                     @survey_plan.id}; #{ee.message}"
    end
  end

  def export
    filename = "export_#{Time.current.strftime("%Y%m%dT%H%M%SZ")}.csv"
    Research::ExportAndUploadSurveyData.perform_later(survey_plan: @survey_plan, filename: filename)
    redirect_to research_survey_plans_path,
                notice: "#{filename} is being created and will be uploaded to Box when ready"
  end

  def cleared_params
    params.require(:research_models_survey_plan).permit(
      :title_for_researchers,
      :title_for_students,
      :description,
      :research_study_id,
      :survey_js_model
    )
  end

  protected

  def get_survey_plan
    @survey_plan = Research::Models::SurveyPlan.find(params[:id])
  end

end
