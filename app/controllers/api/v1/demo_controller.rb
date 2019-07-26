class Api::V1::DemoController < Api::V1::ApiController
  before_action :not_real_production

  resource_description do
    api_versions "v1"
    short_description 'Represents different demo data creation rake tasks'
    description <<-EOS
      Actions represent different demo data creation rake tasks
    EOS
  end

  api :GET, '/demo/users', 'Creates demo users'
  description <<-EOS
    Creates demo users

    #{json_schema(Api::V1::Demo::Users::Representer)}
  EOS
  def users
    Demo::Users.call(
      users: consume!({}, represent_with: Api::V1::Demo::Users::Representer).deep_symbolize_keys
    )

    head :no_content
  end

  api :GET, '/demo/import', 'Imports a demo book'
  description <<-EOS
    Imports a demo book

    #{json_schema(Api::V1::Demo::Import::Representer)}
  EOS
  def import
    catalog_offering = Demo::Import.call(
      import: consume!({}, represent_with: Api::V1::Demo::Import::Representer).deep_symbolize_keys
    ).outputs.catalog_offering

    respond_with(
      { catalog_offering: catalog_offering.attributes.slice('id', 'title') },
      represent_with: Api::V1::Demo::CatalogOfferingRepresenter, location: nil
    )
  end

  api :GET, '/demo/course', 'Creates a demo course and enrolls demo teachers and students'
  description <<-EOS
    Creates a demo course and enrolls demo teachers and students

    #{json_schema(Api::V1::Demo::Course::Representer)}
  EOS
  def course
    course = Demo::Course.call(
      course: consume!({}, represent_with: Api::V1::Demo::Course::Representer).deep_symbolize_keys
    ).outputs.course

    respond_with(
      { course: course.attributes.slice('id', 'name') },
      represent_with: Api::V1::Demo::CourseRepresenter, location: nil
    )
  end

  api :GET, '/demo/assign', 'Creates demo task_plans and tasks'
  description <<-EOS
    Creates demo task_plans and tasks

    #{json_schema(Api::V1::Demo::Assign::Representer)}
  EOS
  def assign
    Demo::Assign.call(
      assign: consume!({}, represent_with: Api::V1::Demo::Assign::Representer).deep_symbolize_keys
    )

    head :no_content
  end

  api :GET, '/demo/work', 'Works demo tasks'
  description <<-EOS
    Works demo tasks

    #{json_schema(Api::V1::Demo::Work::Representer)}
  EOS
  def work
    Demo::Work.call(
      work: consume!({}, represent_with: Api::V1::Demo::Work::Representer).deep_symbolize_keys
    )

    head :no_content
  end

  protected

  def not_real_production
    raise(SecurityTransgression, :real_production) if IAm.real_production?
  end
end
