class Research::SurveyPlansController < Research::BaseController

  before_filter :get_survey_plan, only: [:edit, :update, :preview, :publish, :hide]

  def new
    @survey_plan = Research::Models::SurveyPlan.new
  end

  def create
    @survey_plan = Research::Models::SurveyPlan.new(cleared_params)

    respond_to do |format|
      if @survey_plan.save
        format.html { redirect_to research_survey_plans_path,
                                  notice: 'Survey Plan was successfully created.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @survey_plan.update_attributes(cleared_params)
        format.html { redirect_to research_survey_plan_path(@survey_plan),
                                  notice: 'Survey plan updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def preview
  end

  def publish
    respond_to do |format|
      begin
        Research::PublishSurveyPlan[survey_plan: @survey_plan]
        format.html { redirect_to research_survey_plans_path, notice: "Published survey plan #{@survey_plan.id}"}
      rescue
        format.html { redirect_to research_survey_plans_path, alert: "Could not publish survey plan #{@survey_plan.id}"}
      end
    end
  end

  def hide
    respond_to do |format|
      begin
        Research::HideSurveyPlan[survey_plan: @survey_plan]
        format.html { redirect_to research_survey_plans_path, notice: "Permanently hid survey plan #{@survey_plan.id}"}
      rescue
        format.html { redirect_to research_survey_plans_path, alert: "Could not hide survey plan #{@survey_plan.id}"}
      end
    end
  end

  def cleared_params
    params[:research_models_survey_plan].permit(
      :title_for_researchers,
      :title_for_students,
      :description,
      :research_study_id,
      :survey_js_model
    )
  end

  protected

  def get_survey_plan
    @survey_plan = Research::Models::SurveyPlan.find(params[:survey_plan_id] || params[:id])
  end

end
