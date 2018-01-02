class Research::SurveyPlansController < Research::BaseController

  def new
    @survey_plan = Research::Models::SurveyPlan.new
  end

  def create
    debugger
    @survey_plan = Research::Models::SurveyPlan.new(cleared_params)# params[:research_models_survey_plan])

    respond_to do |format|
      if @survey_plan.save
        format.html { redirect_to research_survey_plan_path(@survey_plan),
                                  notice: 'Survey Plan was successfully created.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  def edit
    @survey_plan = Research::Models::SurveyPlan.find(params[:id])
  end

  def update
    @survey_plan = Research::Models::SurveyPlan.find(params[:id])

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
    @survey_plan = Research::Models::SurveyPlan.find(params[:survey_plan_id])
  end

  def cleared_params
    params[:research_models_survey_plan].permit(:title, :description, :research_study_id, :survey_js_model)
  end

end
