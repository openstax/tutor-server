class Demo::Base
  CONFIG_BASE_DIR = "#{Rails.root}/config/demo"

  protected

  #############################################################################
  #
  # HELPERS
  #
  #############################################################################

  def sign_contract(user:, name:)
    string_name = name.to_s
    return unless FinePrint::Contract.where(name: string_name).exists?
    FinePrint.sign_contract(user.to_model, string_name)
  end

  def new_user(
    username:, name: nil, password: nil, sign_contracts: true, faculty_status: nil, school_type: nil
  )
    password ||= Rails.application.secrets.demo_user_password

    first_name, last_name = name.split(' ')
    raise "#{name} is not a full name" if last_name.nil?

    # The password will be set if stubbing is disabled
    user ||= run(User::CreateUser, username: username,
                                   password: password,
                                   first_name: first_name,
                                   last_name: last_name,
                                   faculty_status: faculty_status,
                                   school_type: school_type).outputs.user

    if sign_contracts
      sign_contract(user: user, name: :general_terms_of_use)
      sign_contract(user: user, name: :privacy_policy)
    end

    user
  end

  def user_for_username(username)
    User::User.find_by_username(username)
  end

  def find_or_create_user_by_username(username, options = {})
    user_for_username(username) || new_user(options.merge(username: username))
  end

  def find_catalog_offering_by_salesforce_book_name(salesforce_book_name)
    Catalog::GetOffering[ salesforce_book_name: salesforce_book_name ]
  end

  def find_demo_course_by_name!(name)
    CourseProfile::Models::Course.order(created_at: :desc).find_by!(name: name, is_test: true)
  end

  def auto_assign_students_for_period(period)
    Hash[
      (period.students || []).map.with_index do |username, i|
        score = if 0 == i%5 then 'i'
                elsif 0 == i%10 then 'ns'
                else
                  70 + rand(30)
                end
        [username, score]
      end
    ]
  end

  def get_auto_assignments(content)
    content.auto_assign.map do |settings|
      book_locations = content.course.ecosystem.pages.map(&:book_location).sample(settings.steps)

      1.upto(settings.generate).map do |number|
        Hashie::Mash.new(
          type: settings.type,
          title: "#{settings.type.titleize} #{number}",
          num_exercises: settings.steps,
          book_locations: book_locations,
          periods: content.periods.map do |period|
            {
              id: period.id,
              opens_at: (number + 3).days.ago,
              due_at:  (number).days.ago,
              students: auto_assign_students_for_period(period)
            }
          end
        )
      end
    end
  end

  def students
    @students ||= Hashie::Mash.load(File.join(CONFIG_BASE_DIR, 'people/students.yml'))
  end

  def teachers
    @teachers ||= Hashie::Mash.load(File.join(CONFIG_BASE_DIR, 'people/teachers.yml'))
  end

  def log(level = :info, &block)
    Rails.logger.tagged(self.class.name) { |logger| logger.public_send(level, &block) }
  end

  def set_random_seed(random_seed = nil)
    # By default, choose a fixed seed for repeatability and fewer surprises
    @randomizer = Random.new(random_seed || 1234789)
  end

  def randomizer
    @randomizer || set_random_seed
  end
end
