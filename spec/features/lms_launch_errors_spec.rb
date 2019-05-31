require 'rails_helper'
require 'feature_js_helper'

# This spec exists to capture screenshots of LMS error messages; does not need to be run
# in general

class LmsErrorPageSpecsController < LmsController
  skip_before_action :authenticate_user!

  def page
    case params[:page]
    when 'unsupported_role'
      fail_for_unsupported_role
    when 'lms_disabled'
      fail_for_lms_disabled(launch, nil)
    when 'already_used'
      fail_for_already_used
    when 'invalid_key_secret'
      fail_for_invalid_key_secret(launch)
    when 'missing_required_fields'
      ll = launch
      ll[:missing_required_fields] = [:tool_consumer_instance_guid, :context_id, :something_else]
      fail_for_missing_required_fields(ll)
    when 'catchall'
      fail_with_catchall_message(nil)
    else
      raise "Unknown page #{params[:page]}"
    end
  end

  protected

  def launch
    launch = OpenStruct.new(:is_student? => (params[:case] == 'student' ? true : false))
  end
end

if screenshots_enabled?

  RSpec.feature 'LMS launch error views', js: true do

    scenario 'unsupported role' do
      visit 'specs/lms_error_page/unsupported_role'
      screenshot!
    end

    context 'lms disabled' do
      scenario 'students' do
        visit 'specs/lms_error_page/lms_disabled/student'
        screenshot!
      end

      scenario 'teachers' do
        visit 'specs/lms_error_page/lms_disabled/teacher'
        screenshot!
      end
    end

    context 'course keys already used' do
      scenario 'students' do
        visit 'specs/lms_error_page/course_keys_already_used/student'
        screenshot!
      end

      scenario 'teacher' do
        visit 'specs/lms_error_page/course_keys_already_used/teacher'
        screenshot!
      end
    end

    scenario 'catchall' do
      visit 'specs/lms_error_page/catchall'
      screenshot!
    end

    scenario 'reused old launch' do
      visit 'specs/lms_error_page/already_used'
      screenshot!
    end

    context 'invalid_key_secret' do
      scenario 'students' do
        visit 'specs/lms_error_page/invalid_key_secret/student'
        screenshot!
      end

      scenario 'teacher' do
        visit 'specs/lms_error_page/invalid_key_secret/teacher'
        screenshot!
      end
    end

    context 'missing required fields' do
      scenario 'students' do
        visit 'specs/lms_error_page/missing_required_fields/student'
        screenshot!
      end

      scenario 'teacher' do
        visit 'specs/lms_error_page/missing_required_fields/teacher'
        screenshot!
      end
    end

  end

end
