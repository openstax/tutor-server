class Research::BrainsController < Research::BaseController

  # Research::BaseController makes sure users are researchers

  def index
    @study = Research::Models::Study.find(params[:study_id])
  end

  def new
    @study = Research::Models::Study.find(params[:study_id])
    @brain = Research::Models::StudyBrain.new(allowed_params.merge(study: @study))
  end

  def edit
    @brain = Research::Models::StudyBrain.find(params[:id])
  end

  def destroy
    brain = Research::Models::StudyBrain.find(params[:id])
    brain.destroy
    redirect_to research_study_path brain.study
  end

  def update
    brain = Research::Models::StudyBrain.find(params[:id])
    brain.update_attributes allowed_params
    render_updated brain
  end

  def create
    render_updated Research::Models::StudyBrain.create(
      allowed_params.merge(research_study_id: params[:study_id])
    )
  end

  protected

  def render_updated(brain)
    if brain.errors.none?
      redirect_to research_study_path brain.study
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
