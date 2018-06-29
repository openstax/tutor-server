class Research::CohortsController < Research::BaseController

  before_action :get_study, only: [:create]
  before_action :get_cohort, only: [:show, :edit, :update, :destroy, :reassign_members]

  def new
    @cohort = Research::Models::Cohort.new
  end

  def create
    cohort = Research::Models::Cohort.new(name: params[:research_models_cohort][:name], study: @study)
    if cohort.save
      flash[:notice] = "Cohort created"
      redirect_to research_study_path(@study)
    else
      flash[:alert] = cohort.errors.full_messages
      render :new
    end
  end

  def edit
  end

  def update
    if @cohort.update_attributes(params[:research_models_cohort].permit(:name, :is_accepting_members))
      flash[:notice] = "Cohort updated"
      redirect_to research_cohort_path(@cohort)
    else
      flash[:alert] = @cohort.errors.full_messages
      render :edit
    end
  end

  def show
  end

  def destroy
    if @cohort.destroy
      flash[:notice] = "Cohort #{@cohort.name} deleted"
      redirect_to research_study_path(@cohort.study)
    else
      flash[:error] = @cohort.errors.full_messages
      redirect_to research_cohort_path(@cohort)
    end
  end

  def reassign_members
    result = Research::ReassignMembers.call(@cohort)

    if result.errors.none?
      flash[:notice] = "Successfully reassigned cohort members"
    else
      flash[:error] = result.errors.map(&:translate).join("; ")
    end

    redirect_to research_cohort_path(@cohort)
  end

  protected

  def get_study
    @study = Research::Models::Study.find(params[:study_id])
  end

  def get_cohort
    @cohort = Research::Models::Cohort.find(params[:id] || params[:cohort_id])
  end

end
