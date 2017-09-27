class Lms::Simulator

  def initialize(spec)
    @spec = spec
    @apps_by_key = {}
    @apps_by_course = {}
    @launch_defaults = {}
    @active_students = {}
    @dropped_students = {}
    @teachers = {}
    @administrators = {}
    @sourcedids = {}
    @next_int = -1

    succeed_when_receive_score_for_dropped_student!
  end

  def tool_consumer_instance_guid
    @tool_consumer_instance_guid ||= next_int
  end

  def install_tutor(app: nil, key: nil, secret: nil, course:, launch_path: "/lms/launch")
    raise "Course must be a string (a name)" if !course.is_a?(String)

    if app.present?
      @apps_by_key[app.key] =
        @apps_by_course[course] =
          { key: app.key, secret: app.secret, course: course, launch_path: launch_path}
    elsif key.present? && secret.present?
      @apps_by_key[key] =
        @apps_by_course[course] =
          {key: key, secret: secret, course: course, launch_path: launch_path}
    else
      raise "Must supply app OR (key AND secret)"
    end
  end

  def add_student(identifier)
    @active_students[identifier] = true
  end

  def add_teacher(identifier)
    @teachers[identifier] = true
  end

  def add_administrator(identifier)
    @administrators[identifier] = true
  end

  def drop_student(identifier)
    raise "No such active student '#{identifier}'" if @active_students[identifier].nil?
    @dropped_students[identifier] = @active_students.delete(identifier)
  end

  def fail_when_receive_score_for_dropped_student!
    @behavior_when_receive_score_for_dropped_student = :fail
  end

  def succeed_when_receive_score_for_dropped_student!
    @behavior_when_receive_score_for_dropped_student = :succeed
  end

  def launch(user: nil, course: nil, assignment: nil)
    user ||= @launch_defaults[:user]
    course ||= @launch_defaults[:course]
    assignment ||= @launch_defaults[:assignment]

    raise "Course must be set or have a default in a launch" if course.blank?
    raise "User must be set or have a default in a launch" if user.blank?

    app = @apps_by_course[course]

    # This request_params setting we might want to eventually specialize by
    # LMS company.

    request_params = {
      user_id: user,
      lis_person_name_full: "Full_Name For_#{user.gsub(/\W/,'_')}",
      # oauth_nonce: next_int,
      # oauth_consumer_key: app[:key],
      lti_message_type: "basic-lti-launch-request",
      tool_consumer_instance_guid: tool_consumer_instance_guid,
      context_id: course
    }

    if is_active_student?(user) && assignment.present?
      request_params.merge!({
        lis_outcome_service_url: "blah",
        lis_result_sourcedid: sourcedid!(user: user, assignment: assignment),
      })
    end

    roles = []
    roles.push(IMS::LIS::Roles::Context::URNs::Learner) if is_active_student?(user)
    roles.push(IMS::LIS::Roles::Context::URNs::Instructor) if is_teacher?(user)
    roles.push(IMS::LIS::Roles::Context::URNs::Administrator) if is_administrator?(user)

    request_params.merge!({
      roles: roles.join(',')
    })

    sign!(request_params, app)

    spec.post app[:launch_path], request_params
  end

  def sign!(request_params, app)
    # Herein is some non-straightforward code that uses the oauth library to sign
    # launch parameters.  The messy part is because we can't just use the oauth
    # token directly to do the post and sign at the same time -- we need to get
    # the signed parameters out so that rspec can do the post so that the message
    # makes it to the right place in our tests.

    rspec_dummy_url = "http://www.example.com/"
    auth = OAuth::Consumer.new(app[:key], app[:secret], site: rspec_dummy_url)
    token = OAuth::AccessToken.new(auth)

    # Remove leading / so don't get a double // in the URL (signing is a picky thing)
    launch_path = app[:launch_path].gsub(/^\//,'')

    temp_request = auth.create_signed_request(
      :post,
      URI("#{rspec_dummy_url}#{launch_path}"),   # if don't use a full URI, host gets dropped
      token,
      {},
      request_params,
      {}                                         # headers
    )

    # Pull the oauth fields out of the temp request and stick them into the inputted
    # request_params.
    request_params.merge!(
      temp_request.get_fields("authorization")[0]
                  .split(',')
                  .each_with_object({}) do |ff, hash|
                    key = ff.split("=")[0].gsub("OAuth ", '').strip
                    value = URI.unescape(ff.split("=")[1].gsub(/"/,'').strip)
                    hash[key] = value
                  end
    )
  end


  def set_launch_defaults(defaults)
    @launch_defaults = defaults.dup
  end

  def sourcedid!(user:, assignment:)
    @sourcedids["#{user}:#{assignment}"] ||= next_int.to_s
  end

  def next_int
    @next_int += 1
  end

  protected

  attr_reader :spec

  def new_launch
    Launch.new(self)
  end

  def add_assignment(name)
    @assignments[name] ||= {
      sourcedids: {}
    }
  end

  def is_active_student?(identifier)
    @active_students[identifier].present?
  end

  def is_teacher?(identifier)
    @teachers[identifier].present?
  end

  def is_administrator?(identifier)
    @administrators[identifier].present?
  end

end
