class Api::V1::DemoController < Api::V1::ApiController
  before_action :not_real_production

  resource_description do
    api_versions "v1"
    short_description 'Represents different demo data creation rake tasks'
    description <<-EOS
      Actions represent different demo data creation rake tasks
    EOS
  end

  api :GET, '/demo/all', 'Runs all demo routines in succession'
  description <<-EOS
    Runs all demo routines in succession

    #{json_schema(Api::V1::Demo::AllRepresenter)}
  EOS
  def all
    jobba_status_id = Demo::All.perform_later consume_hash(Api::V1::Demo::AllRepresenter)

    render json: { jobba_status_id: jobba_status_id }, status: :accepted
  end

  api :GET, '/demo/users', 'Creates demo users'
  description <<-EOS
    Creates demo users

    #{json_schema(Api::V1::Demo::Users::Representer)}
  EOS
  def users
    users = Demo::Users.call(users: consume_hash(Api::V1::Demo::Users::Representer)).outputs.users

    render json: {
      users: users.map { |user| Api::V1::Demo::UserRepresenter.new(user).to_hash }
    }, location: nil, status: :ok
  end

  api :GET, '/demo/import', 'Imports a demo book'
  description <<-EOS
    Imports a demo book

    #{json_schema(Api::V1::Demo::Import::Representer)}
  EOS
  def import
    jobba_status_id = Demo::Import.perform_later(
      import: consume_hash(Api::V1::Demo::Import::Representer)
    )

    render json: { jobba_status_id: jobba_status_id }, status: :accepted
  end

  api :GET, '/demo/course', 'Creates a demo course and enrolls demo teachers and students'
  description <<-EOS
    Creates a demo course and enrolls demo teachers and students

    #{json_schema(Api::V1::Demo::Course::Representer)}
  EOS
  def course
    course = Demo::Course.call(
      course: consume_hash(Api::V1::Demo::Course::Representer)
    ).outputs.course

    render json: {
      course: Api::V1::Demo::CourseRepresenter.new(course).to_hash
    }, location: nil, status: :ok
  end

  api :GET, '/demo/assign', 'Creates demo task_plans and tasks'
  description <<-EOS
    Creates demo task_plans and tasks

    #{json_schema(Api::V1::Demo::Assign::Representer)}
  EOS
  def assign
    task_plans = Demo::Assign.call(
      assign: consume_hash(Api::V1::Demo::Assign::Representer)
    ).outputs.task_plans

    render json: {
      task_plans: task_plans.map do |task_plan|
        Api::V1::Demo::Assign::TaskPlan::Representer.new(task_plan).to_hash
      end
    }, location: nil, status: :ok
  end

  api :GET, '/demo/work', 'Works demo tasks'
  description <<-EOS
    Works demo tasks

    #{json_schema(Api::V1::Demo::Work::Representer)}
  EOS
  def work
    Demo::Work.call work: consume_hash(Api::V1::Demo::Work::Representer)

    head :no_content
  end

  protected

  def not_real_production
    raise(SecurityTransgression, :real_production) if IAm.real_production?
  end

  def consume_hash(representer_class)
    consume!(Hashie::Mash.new, represent_with: representer_class).deep_symbolize_keys
  end
end
