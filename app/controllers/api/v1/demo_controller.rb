class Api::V1::DemoController < Api::V1::ApiController
  respond_to :html
  skip_before_action :force_json_content_type

  before_action :not_real_production, :verify_requested_format!

  rescue_from ActiveRecord::RecordInvalid, with: :render_api_errors

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
    # This demo routine takes too long and consumes too much memory to ever run inline
    jobba_status_id = Delayed::Worker.with_delay_jobs(true) do
      Demo::All.perform_later consume_hash(Api::V1::Demo::AllRepresenter)
    end

    render_job_info jobba_status_id
  end

  api :GET, '/demo/users', 'Creates demo users'
  description <<-EOS
    Creates demo users

    #{json_schema(Api::V1::Demo::Users::Representer)}
  EOS
  def users
    out = Demo::Users.call(users: consume_hash(Api::V1::Demo::Users::Representer)).outputs

    render json: Api::V1::Demo::Users::Representer.new(out).to_hash, location: nil, status: :ok
  end

  api :GET, '/demo/import', 'Imports a demo book'
  description <<-EOS
    Imports a demo book

    #{json_schema(Api::V1::Demo::Import::Representer)}
  EOS
  def import
    # This demo routine takes too long and consumes too much memory to ever run inline
    jobba_status_id = Delayed::Worker.with_delay_jobs(true) do
      Demo::Import.perform_later import: consume_hash(Api::V1::Demo::Import::Representer)
    end

    render_job_info jobba_status_id
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
      course: Api::V1::Demo::Course::CourseRepresenter.new(course).to_hash
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
        Api::V1::Demo::Assign::Course::TaskPlan::Representer.new(task_plan).to_hash
      end
    }, location: nil, status: :ok
  end

  api :GET, '/demo/work', 'Works demo tasks'
  description <<-EOS
    Works demo tasks

    #{json_schema(Api::V1::Demo::Work::Representer)}
  EOS
  def work
    task_plans = Demo::Work.call(
      work: consume_hash(Api::V1::Demo::Work::Representer)
    ).outputs.task_plans

    render json: {
      task_plans: task_plans.map do |task_plan|
        Api::V1::Demo::TaskPlanRepresenter.new(task_plan).to_hash
      end
    }, location: nil, status: :ok
  end

  protected

  def not_real_production
    raise(SecurityTransgression, :real_production) if IAm.real_production?
  end

  # Remove blank strings coming from unfilled form inputs (so we replace them with default values)
  def remove_blank_strings!(obj)
    case obj
    when Hash
      obj.delete_if { |key, value| remove_blank_strings!(value) == '' }
    when Array
      obj.delete_if { |value| remove_blank_strings!(value) == '' }
    else
      obj
    end
  end

  def parse_book_indices!(obj)
    course = obj['course']
    return obj if course.nil?

    task_plans = course['task_plans']
    return obj if task_plans.nil?

    task_plans.each do |task_plan|
      task_plan['book_indices'] = JSON.parse task_plan['book_indices']
    end

    obj
  end

  def consume_hash(representer_class)
    if request.content_type.include?('json')
      consume!(Demo::Mash.new, represent_with: representer_class).deep_symbolize_keys
    else # attempt to parse the params hash
      representer_class.new(Demo::Mash.new).from_hash(
        parse_book_indices!(remove_blank_strings!(params.permit!.to_h))
      ).deep_symbolize_keys
    end
  end

  def render_job_info(jobba_status_id)
    if jobba_status_id.nil?
      head :no_content
    else
      render json: { job: { id: jobba_status_id, url: api_job_url(jobba_status_id) } },
             status: :accepted
    end
  end
end
