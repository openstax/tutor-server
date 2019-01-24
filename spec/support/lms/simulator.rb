require 'webmock/rspec'

class Lms::Simulator

  attr_reader :last_launch

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
    @reverse_sourcedids = {}
    @reuse_sourcedids = true
    @next_int = -1
    @last_launch = nil

    succeed_when_receive_score_for_dropped_student!
    stub_outcome_url
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

  def fail_when_receive_score_for_dropped_student?
    :fail == @behavior_when_receive_score_for_dropped_student
  end

  def reuse_sourcedids!
    @reuse_sourcedids = true
  end

  def do_not_reuse_sourcedids!
    @reuse_sourcedids = false
  end

  def launch(user: nil, course: nil, assignment: nil, drop_these_fields: [])
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
      lti_message_type: "basic-lti-launch-request",
      tool_consumer_instance_guid: tool_consumer_instance_guid,
      context_id: course
    }

    if is_active_student?(user) && assignment.present?
      request_params.merge!({
        lis_outcome_service_url: outcome_url,
        lis_result_sourcedid: sourcedid!(user: user, assignment: assignment),
        resource_link_id: assignment,
      })
    end

    roles = []
    roles.push(IMS::LIS::Roles::Context::URNs::Learner) if is_active_student?(user)
    roles.push(IMS::LIS::Roles::Context::URNs::Instructor) if is_teacher?(user)
    roles.push(IMS::LIS::Roles::Context::URNs::Administrator) if is_administrator?(user)

    request_params.merge!({
      roles: roles.join(',')
    })

    [drop_these_fields].flatten.compact.each {|field| request_params.delete(field)}

    sign!(request_params, app)

    spec.post app[:launch_path], request_params

    @last_launch = {
      launch_path: app[:launch_path],
      request_params: request_params
    }
  end

  def repeat_last_launch
    raise "There is no 'last launch' to repeat" if @last_launch.nil?
    spec.post @last_launch[:launch_path], @last_launch[:request_params]
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
    if @reuse_sourcedids
      @sourcedids["#{user}:#{assignment}"] ||= begin
        value = next_int.to_s
        @reverse_sourcedids[value] = "#{user}:#{assignment}"
        value
      end
    else
      value = next_int.to_s
      # Don't really need to track in @sourcedids since not reusing (not reissuing)
      # but keep for tracking purposes.
      @sourcedids["#{user}:#{assignment}"] ||= []
      @sourcedids["#{user}:#{assignment}"].push(value)
      @reverse_sourcedids[value] = "#{user}:#{assignment}"
      value
    end
  end

  def next_int
    @next_int += 1
  end

  #############################################################################
  #
  # Outcomes
  #

  def stub_outcome_url
    spec.stub_request(:post, outcome_url).to_return do |request|
      begin
        xml = Nokogiri::XML.parse(request.body,&:noblanks)

        sourcedid = xml.at_css('resultRecord sourcedGUID sourcedId').content
        raise "Could not find sourcedid in XML" if sourcedid.blank?

        user_assignment = @reverse_sourcedids[sourcedid]
        raise "Unknown sourcedid #{sourcedid}" if user_assignment.blank?

        user, assignment = user_assignment.split(":")

        score = xml.at_css('resultScore textString').content.to_f
        received_score(user: user, assignment: assignment, score: score)

        raise "User is dropped" if !is_active_student?(user) && fail_when_receive_score_for_dropped_student?

        { body: outcome_response_xml(code_major: "success") }
      rescue StandardError => ee
        { body: outcome_response_xml(code_major: "failure", description: ee.message) }
      end
    end
  end

  def outcome_response_xml(code_major:, description: "")
    <<-EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <imsx_POXEnvelopeResponse xmlns = "http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
        <imsx_POXHeader>
          <imsx_POXResponseHeaderInfo>
            <imsx_version>V1.0</imsx_version>
            <imsx_messageIdentifier>4560</imsx_messageIdentifier>
            <imsx_statusInfo>
              <imsx_codeMajor>#{code_major}</imsx_codeMajor>
              <imsx_severity>status</imsx_severity>
              <imsx_description>#{description}</imsx_description>
              <imsx_messageRefIdentifier>999999123</imsx_messageRefIdentifier>
              <imsx_operationRefIdentifier>replaceResult</imsx_operationRefIdentifier>
            </imsx_statusInfo>
          </imsx_POXResponseHeaderInfo>
        </imsx_POXHeader>
        <imsx_POXBody>
          <replaceResultResponse/>
        </imsx_POXBody>
      </imsx_POXEnvelopeResponse>
    EOS
  end

  def received_score(user:, assignment:, score:); end

  def expect_to_receive_score(user:, assignment:, score:)
    this = self
    spec.instance_eval do
      expect(this).to receive(:received_score).with(user: user, assignment: assignment, score: score)
    end
  end

  def expect_not_to_receive_score(user:, assignment:)
    this = self
    spec.instance_eval do
      expect(this).not_to receive(:received_score).with(user: user, assignment: assignment, score: anything())
    end
  end

  #
  #############################################################################

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

  def simulator_url
    "http://simlms/"
  end

  def outcome_url
    "#{simulator_url}outcome"
  end

  protected

  attr_reader :spec

  def new_launch
    Launch.new(self)
  end


end
