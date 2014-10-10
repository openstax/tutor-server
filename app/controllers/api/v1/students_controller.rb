module Api::V1
  class StudentsController < Api::V1::ApiController

    before_filter :get_klass, only: [:index, :create]
    before_filter :get_student, only: [:show, :update, :destroy]

    resource_description do
      api_versions "v1"
      short_description 'Represents a student in OpenStax Tutor'
      description <<-EOS
        View or manage students that use OpenStax Tutor.
      EOS
    end

    #########
    # index #
    #########

    api :GET,
        '/schools/:school_id/courses/:course_id/classes/:class_id/students',
        'Returns a list of students in a given class'
    description <<-EOS
      Returns a list of students in a given class.

      #{json_schema(Api::V1::StudentSearchRepresenter, include: :readable)}        
    EOS
    def index
      standard_index(@klass.students)
    end

    ########
    # show #
    ########

    api :GET,
        '/schools/:school_id/courses/:course_id/classes/:class_id/students/:student_id',
        'Returns information about the given student'
    description <<-EOS
      Returns information about the given student.

      #{json_schema(Api::V1::StudentRepresenter, include: :readable)}        
    EOS
    def show
      standard_read(@student)
    end

    ##########
    # create #
    ##########

    api :POST, '/schools/:school_id/courses/:course_id/classes/:class_id/students',
               'Adds a new student to the given class'
    description <<-EOS
      Adds a new student to the given class.

      #{json_schema(Api::V1::StudentRepresenter, include: :writeable)}        
    EOS
    def show
      standard_nested_create(Student.new, :klass, @klass)
    end

    ##########
    # update #
    ##########

    api :PATCH,
        '/schools/:school_id/courses/:course_id/classes/:class_id/students/:student_id',
        'Updates attributes of the given student'
    description <<-EOS
      Updates attributes of the given student.

      #{json_schema(Api::V1::StudentRepresenter, include: :writeable)}        
    EOS
    def show
      standard_update(@student)
    end

    ###########
    # destroy #
    ###########

    api :DELETE,
        '/schools/:school_id/courses/:course_id/classes/:class_id/students/:student_id',
        'Removes the given student from the given class'
    description <<-EOS
      Removes the given student from the given class.      
    EOS
    def destroy
      standard_destroy(@student)
    end

    protected

    def get_klass
      @klass = Klass.find(params[:klass_id])
    end

    def get_student
      @student = Student.find(params[:id])
    end

  end
end
