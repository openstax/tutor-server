class Api::V1::Cc::TasksController < Api::V1::ApiController

  after_filter :set_cors_headers
  skip_before_action :verify_authenticity_token, only: :show

  resource_description do
    api_versions "v1"
    short_description 'Represents a concept coach task'
    description <<-EOS
      see `/api/tasks`
    EOS
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, 'cc/tasks/:cnx_book_id/:cnx_page_id', 'Gets the Concept Coach Task for the given CNX page'
  description <<-EOS
    The `cnx_book_id` and `cnx_page_id` should not contain version information.
    #{json_schema(Api::V1::TaskRepresenter, include: :readable)}
  EOS
  def show
    # THIS IS JUST A HACKED STUBBED IMPLEMENTATION!!

    # Real implementation should, among other things:
    #   1) Error out if the user isn't in a course with the provided book/page ID
    #   2) return 4xx error if IDs contain versions, e.g. UUID@42

    # FIXME
    # OpenstaxAPI calls User::User.where().first which fails since User::User is a proxy and lacks .where
    # https://github.com/openstax/openstax_api/pull/36
    # current_human_user = User::User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token

    if current_human_user.nil? || current_human_user.is_anonymous?
      head :forbidden
    elsif params[:cnx_book_id].blank? || params[:cnx_page_id].blank?
      head :unprocessable_entity
    else
      # Instead of really attaching a task to a user, store it in the session (hack)
      hash = Digest::SHA1.hexdigest(
        current_human_user.id.to_s +
        params[:cnx_book_id] +
        params[:cnx_page_id]
      )[0..7]

      task_id = session[hash.to_sym]

      task = task_id.nil? ?
               create_fake_concept_coach_task :
               ::Tasks::Models::Task.find(task_id)

      session[hash.to_sym] = task.id

      respond_with task, represent_with: Api::V1::TaskRepresenter
    end
  end

  # requested by an OPTIONS request type
  def cors_preflight_check
    set_cors_headers
    headers['Access-Control-Max-Age'] = '1728000'
    render :text => '', :content_type => 'text/plain'
  end

  protected

  def create_fake_concept_coach_task
    task =  ::Tasks::BuildTask[
              task_type: :concept_coach,
              title: 'Dummy task title',
              description: 'Dummy task description',
              opens_at: 1000.days.ago,
              feedback_at: 1000.days.ago]

    3.times do
      content_exercise = FactoryGirl.create(:content_exercise)
      strategy = ::Content::Strategies::Direct::Exercise.new(content_exercise)
      exercise = ::Content::Exercise.new(strategy: strategy)

      step = Tasks::Models::TaskStep.new(task: task)
      step.tasked = TaskExercise[exercise: exercise, task_step: step]
      task.task_steps << step
    end

    task.save!
    task
  end

  def set_cors_headers
    headers['Access-Control-Allow-Origin']   = validated_cors_origin
    headers['Access-Control-Allow-Methods']  = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Credentials'] = 'true'
    headers['Access-Control-Allow-Headers']  = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

  def validated_cors_origin
    origin = request.headers["HTTP_ORIGIN"]
    return '' if origin.blank?
    Rails.application.secrets.cc_origins.each do | host |
      return origin if origin.match(/^#{host}/)
    end
    '' # an empty string will disallow any access
  end
end
