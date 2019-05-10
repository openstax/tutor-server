require 'hashie/mash'
require 'fork_with_connection'
require_relative 'config/content'

class Demo::Base
  CONFIG_BASE_DIR = "#{Rails.root}/config/demo"

  include ForkWithConnection

  protected

  #############################################################################
  #
  # HELPERS
  #
  #############################################################################

  # Lev override to prevent automatic transactions while still allowing other routines to be called
  def self.disable_automatic_lev_transactions
    define_method(:transaction_run_by?) do |who|
      return false if who == self
      super
    end
  end

  def self.max_processes
    Integer(ENV['DEMO_MAX_PROCESSES']) rescue 4
  end

  # Runs the given code in parallel processes
  # Calling process must not be in a transaction
  # Args should be Enumerables and will be passed to the given block in properly-sized slices
  # You will still have to iterate through the yielded values
  # The index for the first element in the original array is also passed in as the last argument
  # Returns the PID's for the spawned processes
  def in_parallel(*args, max_processes: nil, transaction: false)
    arg_size = args.first.size
    raise 'Arguments must have the same size' unless args.all?{ |arg| arg.size == arg_size }

    # This is the maximum number of processes spawned for each call to this method
    max_processes ||= self.class.max_processes

    if arg_size == 0 || max_processes < 1
      log(:debug) { "Processes: 0 (inline processing) - Slice size: #{arg_size}" }

      return yield *[args + [0]]
    end

    Rails.application.eager_load!

    # Use max_processes unless too few args given
    num_processes = [arg_size, max_processes].min

    # Calculate slice_size
    slice_size = (arg_size/num_processes.to_f).ceil

    # Adjust number of processes again if some process would receive an empty array
    num_processes = (arg_size/slice_size.to_f).ceil

    sliced_args = args.map { |arg| arg.each_slice(slice_size) }
    process_args = 0.upto(num_processes - 1).map do |process_index|
      sliced_args.map { |sliced_arg| sliced_arg.next } + [process_index*slice_size]
    end

    child_processes = 0.upto(num_processes - 1).map do |process_index|
      fork_with_connection do
        if transaction
          ActiveRecord::Base.transaction do
            yield *process_args[process_index]
          end
        else
          yield *process_args[process_index]
        end
      end
    end

    @processes ||= []
    @processes += child_processes
  end

  # Waits for all child processes to finish
  # Returns the PID/Status pairs for the processes we had to wait on
  def wait_for_parallel_completion
    return [] if @processes.nil?

    log(:debug) { 'Waiting for child processes to exit...' }

    results = @processes.map { |pid| Process.wait2(pid) }

    @processes = []

    results.each do |result|
      log(:debug) { "PID: #{result.first} - Status: #{result.last.exitstatus}" }
      fatal_error(code: :process_failed) unless result.last.success?
    end

    log(:debug) { 'All child processes exited' }

    results
  end

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
