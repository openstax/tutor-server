require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe UpdatePeriodClues, type: :routine, vcr: VCR_OPTS do

  # These strings have to match whatever values are in the cassettes for this file
  USER_1_IDENTIFIER  =  '21332ca231a015a11df464d759dd7de0da971bd48334ebb050540ec683f548fe'
  USER_2_IDENTIFIER  =  '8e79ebcd72d5061496ad94b471686015dccd126e6a42a3dd122bf15590abe8b7'
  CHAPTER_POOL_UUIDS = ['a4b27cdd-93e3-43a2-bcb5-482bfb1a57f7',
                        '98da2330-310e-400f-aa28-49b4c89cb48d',
                        '508e4ee4-851d-4648-b130-9bacd4efbaab',
                        '1cb673ca-f75b-4424-a94a-920d34817819']
  PAGE_POOL_UUIDS    = ['16cdcb35-a47e-4967-93c3-a841e7b05e6d',
                        'db4e911d-5018-43f7-bb03-ec6808f077cb',
                        '551ba8dd-1224-4024-8f93-e4ae90f47445',
                        '0e5f74dd-204c-4122-a1ab-ca67b2e3519b',
                        'b30ce2b3-fd5f-4f11-954b-57dd985c2dae',
                        '8c21ea7d-2462-431b-aa7e-49184c7e09f6',
                        '945b0a59-4c91-4c45-909d-c6e6eee06801',
                        '3c60e622-9b4f-4e32-97c7-9278f7199013']

  before(:all) do
    @course = Entity::Course.create!

    @period = CreatePeriod[course: @course]
    @second_period = CreatePeriod[course: @course]

    teacher_profile = FactoryGirl.create(:user_profile)
    teacher_strategy = User::Strategies::Direct::User.new(teacher_profile)
    @teacher = User::User.new(strategy: teacher_strategy)

    student_profile = FactoryGirl.create(:user_profile, exchange_read_identifier: USER_1_IDENTIFIER)
    student_strategy = User::Strategies::Direct::User.new(student_profile)
    @student = User::User.new(strategy: student_strategy)

    student_profile_2 = FactoryGirl.create(:user_profile,
                                           exchange_read_identifier: USER_2_IDENTIFIER)
    student_strategy_2 = User::Strategies::Direct::User.new(student_profile_2)
    @second_student = User::User.new(strategy: student_strategy_2)

    @role = AddUserAsPeriodStudent[period: @period, user: @student]
    @second_role = AddUserAsPeriodStudent[period: @second_period, user: @second_student]
    @teacher_role = AddUserAsCourseTeacher[course: @course, user: @teacher]

    VCR.use_cassette("GetCourseGuide/setup_course_guide", VCR_OPTS) do
      capture_stdout do
        CreateStudentHistory[course: @course, roles: [@role, @second_role]]
      end
    end

    CHAPTER_POOL_UUIDS.each_with_index do |uuid, index|
      @course.ecosystems.first.chapters[index].all_exercises_pool.update_attribute(:uuid, uuid)
    end
    PAGE_POOL_UUIDS.each_with_index do |uuid, index|
      @course.ecosystems.first.pages[index].all_exercises_pool.update_attribute(:uuid, uuid)
    end

    @original_client = OpenStax::Biglearn::V1.send :client
    @real_client = OpenStax::Biglearn::V1.use_real_client
  end

  after(:all) do
    OpenStax::Biglearn::V1.instance_variable_set :@client, @original_client

    # Transaction database cleaning causes weird behavior in this spec
    DatabaseCleaner.clean_with :truncation
  end

  before(:each) do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  after(:each) { Rails.cache = @original_cache }

  it 'causes a request to biglearn for every period for every call' do
    expect(@real_client).to receive(:request_clues).exactly(4).times.and_call_original

    described_class[]

    described_class[]
  end

  it 'causes a request to biglearn for every period even if called after the teacher guide' do
    expect(@real_client).to receive(:request_clues).exactly(4).times.and_call_original

    teacher_guide = GetTeacherGuide[role: @teacher_role]
    expect(teacher_guide.size).to eq 2

    described_class[]
  end

  it 'warms up the cache for the teacher guide for an arbitrary course' do
    expect(@real_client).to receive(:request_clues).twice.and_call_original

    described_class[]

    teacher_guide = GetTeacherGuide[role: @teacher_role]
    expect(teacher_guide.size).to eq 2
  end

end
