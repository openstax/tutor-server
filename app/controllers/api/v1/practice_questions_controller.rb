class Api::V1::PracticeQuestionsController < Api::V1::ApiController
  before_action :set_course_and_role
  before_action :error_if_student_and_needs_to_pay, only: [:index, :create, :destroy]

  resource_description do
      api_versions 'v1'
      short_description 'Represents practice questions for a student'
      description <<~DESCRIPTION
        Allows questions to be saved by a student and selected for practice
      DESCRIPTION
    end

  api :GET, '/courses/:course_id/practice_questions',
            'Lists saved practice questions '
  description <<-EOS
    #{json_schema(Api::V1::PracticeQuestionsRepresenter, include: :readable)}
  EOS
  def index
    respond_with @role.practice_questions, represent_with: Api::V1::PracticeQuestionsRepresenter
  end

  api :POST, '/courses/:course_id/practice_questions',
             'Saves a practice question'
  description <<-EOS
    #{json_schema(Api::V1::PracticeQuestionRepresenter, include: :writeable)}
  EOS
  def create
    step = ::Tasks::Models::TaskStep.joins(task: :taskings).find_by(
      task: { taskings: { entity_role_id: @role.id} },
      tasked_id: params[:tasked_exercise_id],
      tasked_type: ::Tasks::Models::TaskedExercise.name
    )

    if step.nil?
      return render_api_errors(:not_found)
    end

    standard_create ::Tasks::Models::PracticeQuestion.new, Api::V1::PracticeQuestionRepresenter do |question|
      question.role = @role
      question.tasked_exercise = step.tasked
      question.exercise = step.tasked.exercise
    end
  end

  api :DELETE, '/courses/:course_id/practice_questions/:id',
               'Removes a practice question'
  description <<-EOS
    #{json_schema(Api::V1::PracticeQuestionRepresenter, include: :readable)}
  EOS
  def destroy
    question = @role.practice_questions.find(params[:id])
    return render_api_errors(:not_found) if question.nil?

    standard_destroy question, Api::V1::PracticeQuestionRepresenter
  end

  protected

  def set_course_and_role
    @course = CourseProfile::Models::Course.find(params[:course_id])
    result = ChooseCourseRole.call(user: current_human_user,
                                   course: @course,
                                   role_id: params[:role_id],
                                   allowed_role_types: [ :student, :teacher_student ])
    if result.errors.any?
      raise(SecurityTransgression, result.errors.map(&:message).to_sentence)
    else
      @role = result.outputs.role
    end
  end
end
