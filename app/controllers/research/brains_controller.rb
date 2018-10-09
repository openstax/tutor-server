class Research::BrainsController < Research::BaseController

  # Research::BaseController makes sure users are researchers

  def index
    @cohort = Research::Models::Cohort.find(params[:cohort_id])
  end

  def new
    @cohort = Research::Models::Cohort.find(params[:cohort_id])
    @brain = Research::Models::StudyBrain.new(allowed_params.merge(cohort: @cohort))
  end

  def edit
    @brain = Research::Models::StudyBrain.find(params[:id])
  end

  def destroy
    brain = Research::Models::StudyBrain.find(params[:id])
    brain.destroy
    redirect_to research_cohort_path brain.cohort
  end

  def update
    brain = Research::Models::StudyBrain.find(params[:id])
    brain.update_attributes allowed_params
    render_updated brain
  end

  def create
    render_updated Research::Models::StudyBrain.create(
      allowed_params.merge(research_cohort_id: params[:cohort_id])
    )
  end

  protected

  def render_updated(brain)
    if brain.errors.none?
      redirect_to research_cohort_path brain.cohort
    else
      @brain = brain
      render :edit
    end
  end

  def allowed_params
    params[:research_models_study_brain] ?
      params.require(:research_models_study_brain).permit(:name, :type, :code) : {}
  end
end
