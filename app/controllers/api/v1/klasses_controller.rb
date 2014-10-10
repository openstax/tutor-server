module Api::V1
  class KlassesController < Api::V1::ApiController

    before_filter :get_course, only: :create
    before_filter :get_klass, only: [:show, :update, :destroy]

    resource_description do
      api_versions "v1"
      short_description 'Represents a class using OpenStax Tutor'
      description <<-EOS
        Read about or manage classes that use OpenStax Tutor.
      EOS
    end

    ########
    # show #
    ########

    api :GET, '/schools/:school_id/courses/:course_id/classes/:class_id',
              'Returns information about the given class'
    description <<-EOS
      Returns information about the given class.

      #{json_schema(Api::V1::KlassRepresenter, include: :readable)}        
    EOS
    def show
      standard_read(@klass)
    end

    ##########
    # create #
    ##########

    api :POST, '/schools/:school_id/courses/:course_id/classes',
               'Creates a class for the given course'
    description <<-EOS
      Creates a class for the given course.

      #{json_schema(Api::V1::KlassRepresenter, include: :writeable)}        
    EOS
    def create
      standard_nested_create(Klass.new, :course, @course)
    end

    ##########
    # update #
    ##########

    api :PATCH, '/schools/:school_id/courses/:course_id/classes/:class_id',
                'Updates attributes of the given class'
    description <<-EOS
      Updates attributes of the given class.

      #{json_schema(Api::V1::KlassRepresenter, include: :writeable)}        
    EOS
    def update
      standard_update(@klass)
    end

    ###########
    # destroy #
    ###########

    api :DELETE, '/schools/:school_id/courses/:course_id/classes/:class_id',
                 'Deletes the given class'
    description <<-EOS
      Deletes the given class.      
    EOS
    def destroy
      standard_destroy(@klass)
    end

    protected

    def get_course
      @course = Course.find(params[:course_id])
    end

    def get_klass
      @klass = Klass.find(params[:id])
    end

  end
end
