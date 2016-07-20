require 'rails_helper'
require 'vcr_helper'
require 'support/biglearn_real_client_vcr_helper'
require 'database_cleaner'

RSpec.describe UpdateClues, type: :routine, vcr: VCR_OPTS do

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
    @course = FactoryGirl.create :entity_course

    @period = CreatePeriod[course: @course]
    @second_period = CreatePeriod[course: @course]

    @teacher = FactoryGirl.create(:user)

    @student = FactoryGirl.create(:user, exchange_read_identifier: USER_1_IDENTIFIER)

    @second_student = FactoryGirl.create(:user, exchange_read_identifier: USER_2_IDENTIFIER)

    @role = AddUserAsPeriodStudent[period: @period, user: @student]
    @second_role = AddUserAsPeriodStudent[period: @second_period, user: @second_student]
    @teacher_role = AddUserAsCourseTeacher[course: @course, user: @teacher]

    VCR.use_cassette("GetCourseGuide/setup_course_guide", VCR_OPTS) do
      capture_stdout do
        CreateStudentHistory[course: @course, roles: [@role, @second_role]]
      end
    end

    page_index = 0
    @course.ecosystems.first.chapters.each_with_index do |chapter, index|
      uuid = CHAPTER_POOL_UUIDS[index]
      chapter.all_exercises_pool.update_attribute(:uuid, uuid)
      chapter.pages.each do |page|
        uuid = PAGE_POOL_UUIDS[page_index]
        page.all_exercises_pool.update_attribute(:uuid, uuid)
        page_index += 1
      end
    end

    @original_client_name = OpenStax::Biglearn::V1.client.name
    @real_client = OpenStax::Biglearn::V1.use_real_client
  end

  after(:all) { OpenStax::Biglearn::V1.use_client_named(@original_client_name) }

  before(:each) do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    # VCR is not threadsafe, so stub out thread creation and process requests inline
    # Return an OpenStruct so we can call .join safely
    allow(Thread).to receive(:new) do |&block|
      block.call
      OpenStruct.new
    end
  end

  after(:each) { Rails.cache = @original_cache }

  context 'all clues' do
    let(:described_args) { { type: :all } }

    it 'causes no requests to biglearn for cc courses' do
      @course.profile.reload.update_attribute(:is_concept_coach, true)

      expect(@real_client).not_to receive(:request_clues)

      described_class[described_args] # 0 requests (CC course)
    end

    it 'causes a request to biglearn for every non-cc period and every user for every call' do
      expect(@real_client).to receive(:request_clues).exactly(8).times.and_call_original

      described_class[described_args] # 4 requests

      described_class[described_args] # 4 requests
    end

    it 'causes requests to biglearn even if called after the teacher guide' do
      expect(@real_client).to receive(:request_clues).exactly(6).times.and_call_original

      teacher_guide = GetTeacherGuide[role: @teacher_role] # 2 requests
      expect(teacher_guide.size).to eq 2

      described_class[described_args] # 4 requests
    end

    it 'warms up the cache for the teacher guide for an arbitrary course' do
      expect(@real_client).to receive(:request_clues).exactly(4).times.and_call_original

      described_class[described_args] # 4 requests

      teacher_guide = GetTeacherGuide[role: @teacher_role] # 0 requests (cached)
      expect(teacher_guide.size).to eq 2
    end

    it 'causes requests to biglearn even if called after the student guide' do
      expect(@real_client).to receive(:request_clues).exactly(5).times.and_call_original

      student_guide = GetStudentGuide[role: @role] # 1 request
      expect(student_guide).to be_present

      described_class[described_args] # 4 requests
    end

    it 'warms up the cache for the student guide for an arbitrary student' do
      expect(@real_client).to receive(:request_clues).exactly(4).times.and_call_original

      described_class[described_args] # 4 requests

      student_guide = GetStudentGuide[role: @role] # 0 requests (cached)
      expect(student_guide).to be_present

      student_guide_2 = GetStudentGuide[role: @second_role] # 0 requests (cached)
      expect(student_guide_2).to be_present
    end
  end

  context 'recent clues' do
    let(:described_args) { { type: :recent } }

    context 'with all recent work' do
      it 'causes no requests to biglearn for cc courses' do
        @course.profile.reload.update_attribute(:is_concept_coach, true)

        expect(@real_client).not_to receive(:request_clues)

        described_class[described_args] # 0 requests (CC course)
      end

      it 'requests recently worked clues from biglearn' do
        expect(@real_client).to receive(:request_clues).exactly(4).times.and_call_original

        described_class[described_args] # 4 requests
      end

      it 'causes requests to biglearn even if called after the teacher guide' do
        expect(@real_client).to receive(:request_clues).exactly(6).times.and_call_original

        teacher_guide = GetTeacherGuide[role: @teacher_role] # 2 requests
        expect(teacher_guide.size).to eq 2

        described_class[described_args] # 4 requests
      end

      it 'warms up the cache for the teacher guide for an arbitrary course' do
        expect(@real_client).to receive(:request_clues).exactly(4).times.and_call_original

        described_class[described_args] # 4 requests

        teacher_guide = GetTeacherGuide[role: @teacher_role] # 0 requests (cached)
        expect(teacher_guide.size).to eq 2
      end

      it 'causes requests to biglearn even if called after the student guide' do
        expect(@real_client).to receive(:request_clues).exactly(5).times.and_call_original

        student_guide = GetStudentGuide[role: @role] # 1 request
        expect(student_guide).to be_present

        described_class[described_args] # 4 requests
      end

      it 'warms up the cache for the student guide for an arbitrary student' do
        expect(@real_client).to receive(:request_clues).exactly(4).times.and_call_original

        described_class[described_args] # 4 requests

        student_guide = GetStudentGuide[role: @role] # 0 requests (cached)
        expect(student_guide).to be_present

        student_guide_2 = GetStudentGuide[role: @second_role] # 0 requests (cached)
        expect(student_guide_2).to be_present
      end
    end

    context 'with some recent work' do
      before(:all) do
        Timecop.freeze(Time.current + 5.minutes)

        @role.taskings.each do |tasking|
          tasking.task.task_steps.select(&:completed?).each do |ts|
            MarkTaskStepCompleted[task_step: ts]
          end
        end
      end

      after(:all)  { Timecop.return }

      it 'causes requests to biglearn only for the recent work' do
        expect(@real_client).to receive(:request_clues).twice.and_call_original

        described_class[described_args] # 2 request (relevant student + period)
      end

      it 'causes requests to biglearn even if called after the student guide' do
        expect(@real_client).to receive(:request_clues).exactly(3).times.and_call_original

        student_guide = GetStudentGuide[role: @role] # 1 request
        expect(student_guide).to be_present

        described_class[described_args] # 2 requests
      end

      it 'warms up the cache for the student guide for students that recently worked problems' do
        expect(@real_client).to receive(:request_clues).twice.and_call_original

        described_class[described_args] # 2 requests

        student_guide = GetStudentGuide[role: @role] # 0 requests (cached)
        expect(student_guide).to be_present
      end

      it 'does not cache clues for students that have not recently worked problems' do
        expect(@real_client).to receive(:request_clues).exactly(3).times.and_call_original

        described_class[described_args] # 2 requests

        student_guide = GetStudentGuide[role: @second_role] # 1 request
        expect(student_guide).to be_present
      end
    end

    context 'without recent work' do
      before(:all) { Timecop.freeze(Time.current + 10.minutes) }
      after(:all)  { Timecop.return }

      it 'does not cause requests to biglearn' do
        expect(@real_client).not_to receive(:request_clues)

        described_class[described_args] # 0 requests (no recent work)
      end
    end
  end

end
