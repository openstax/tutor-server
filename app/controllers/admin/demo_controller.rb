class Admin::DemoController < Admin::BaseController
  before_action :not_real_production, :set_variables

  def all
    render 'form'
  end

  def users
    render 'form'
  end

  def import
    render 'form'
  end

  def course
    render 'form'
  end

  def assign
    render 'form'
  end

  def work
    render 'form'
  end

  protected

  def not_real_production
    raise(SecurityTransgression, :real_production) if IAm.real_production?
  end

  def set_variables
    @page_header = 'Demo Data'
    @config = params[:config].blank? ? Demo::DEFAULT_CONFIG : params[:config]
    @book = params[:book].blank? ? 'phys' : params[:book]
    filename = "#{@book}.yml{,.erb}"
    @type = action_name.to_sym

    config = {}
    (@type == :all ? [ :users, :import, :course, :assign, :work ] : [ @type ]).each do |type|
      Dir[
        File.join Demo::CONFIG_BASE_DIR, @config, type.to_s, '**', "#{@book}.yml{,.erb}"
      ].each do |path|
        string = File.read(path)
        if File.extname(path) == '.erb'
          erb = ERB.new(string)
          erb.filename = path
          string = erb.result
        end
        config[type] = YAML.load(string)
      end
    end

    @model = if @type == :all
      Api::V1::Demo::AllRepresenter.new(Demo::Mash.new).from_hash(config)
    else
      Api::V1::Demo.const_get(@type.to_s.capitalize)::Representer.new(Demo::Mash.new).from_hash(
        config[@type] || {}
      )
    end

    assign = @model&.assign || @model

    (assign.course&.task_plans || []).each do |task_plan|
      task_plan.book_indices = task_plan.book_indices.to_json unless task_plan.book_indices.blank?
    end
  end
end
