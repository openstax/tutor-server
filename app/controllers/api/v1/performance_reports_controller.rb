class Api::V1::PerformanceReportsController < Api::V1::ApiController

  api :POST, '/courses/:course_id/performance/export',
             'Begins the export of the performance report for authorized teachers'
  description <<-EOS
    202 if the role is a teacher of a course
      -- The export background job will be started
  EOS
  def export
    course = CourseProfile::Models::Course.find(params[:id])

    OSU::AccessPolicy.require_action_allowed!(:export, current_api_user, course)

    job_id = Tasks::ExportPerformanceReport.perform_later(course: course,
                                                          role: get_course_role(course: course))

    render_job_id_json(job_id)
  end

  api :GET, '/courses/:course_id/performance/exports',
            'Gets the export history of the performance report for authorized teachers'
  description <<-EOS
    #{json_schema(Api::V1::PerformanceReportExportsRepresenter, include: :readable)}
  EOS
  def exports
    course = CourseProfile::Models::Course.find(params[:id])

    OSU::AccessPolicy.require_action_allowed!(:export, current_api_user, course)

    exports = Tasks::GetPerformanceReportExports[course: course,
                                                 role: get_course_role(course: course)]

    respond_with exports, represent_with: Api::V1::PerformanceReportExportsRepresenter
  end

  api :GET, '/courses/:course_id/performance(/role/:role_id)', 'Returns performance report for the user'
  description <<-EOS
    #{json_schema(Api::V1::PerformanceReport::Representer, include: :readable)}
  EOS
  def index
    course = CourseProfile::Models::Course.find(params[:id])
    preport = GetPerformanceReport[course: course, role: get_course_role(course: course)]

    respond_with(preport, represent_with: Api::V1::PerformanceReport::Representer)
  end

  protected

  def get_course_role(course:)
    result = ChooseCourseRole.call(user: current_human_user,
                                   course: course,
                                   allowed_role_type: :teacher,
                                   role_id: params[:role_id])
    raise(SecurityTransgression, :invalid_role) if result.errors.any?
    result.outputs.role
  end
end
