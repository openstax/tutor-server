class Demo::Base
  protected

  def log(level = :info, &block)
    Rails.logger.tagged(self.class.name) { |logger| logger.public_send(level, &block) }
  end

  def log_status(name = nil)
    name_string = name.blank? ? '' : "#{name}: "
    if errors.empty?
      log(:info) { "#{name_string}Success" }
    else
      log(:error) { "#{name_string}Errors:\n#{errors.inspect}" }
    end
  end

  # Same as Random.srand but does not explode with a nil argument
  def srand(random_seed = nil)
    random_seed.nil? ? Random.srand : Random.srand(random_seed)
  end

  def find_course(course)
    if course[:id].blank?
      raise 'Cannot find a course without an id or name' if course[:name].blank?

      CourseProfile::Models::Course.order(created_at: :desc).find_by! name: course[:name]
    else
      CourseProfile::Models::Course.find course[:id]
    end
  end
end
