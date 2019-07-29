require 'rails_helper'

RSpec.describe 'demo', type: :rake do
  include_context 'rake'

  def expect_review_import(import)
    expect(import[:archive_url_base]).to eq 'https://archive.cnx.org/contents/'
    expect(import[:salesforce_book_name]).to be_in [
      'Biology 2e', 'Physics w Courseware', 'Sociology w Courseware'
    ]
    expect(import[:title]).to(eq('Physics with Courseware')) \
      if import[:salesforce_book_name] == 'Physics w Courseware'
        expect(import[:title]).to(eq('Sociology with Courseware')) \
          if import[:salesforce_book_name] == 'Sociology w Courseware'
    expect(import[:appearance_code]).to be_in [
      'biology_2e', 'college_physics', 'intro_sociology'
    ]
    expect(import[:cnx_book_id]).to be_in [
      '8d50a0af-948b-4204-a71d-4826cba765b8',
      '405335a3-7cff-4df2-a9ad-29062a4af261',
      '02040312-72c8-441e-a685-20e9333f3e1d'
    ]
    expect(import[:reading_processing_instructions].size).to be_in [1, 2, 4]
    import[:reading_processing_instructions].each do |reading_processing_instruction|
      expect(reading_processing_instruction[:css]).not_to be_blank
      expect(reading_processing_instruction[:fragments]).to be_a Array
    end
  end

  def expect_review_course(course)
    expect(course[:course][:name]).to be_in [
      'Biology 2e Review',
      'Physics with Courseware Review',
      'Sociology with Courseware Review'
    ]
    expect(course[:catalog_offering][:title]).to be_in [
      'Biology 2e', 'Physics with Courseware', 'Sociology with Courseware'
    ]
    expect(course[:is_college]).to eq true
    expect(course[:teachers]).to eq [username: 'reviewteacher']
    expect(course[:periods].size).to eq 2
    course[:periods].each do |period|
      expect(period[:name]).to be_in ['1st', '2nd']
      expect(period[:students].size).to eq 3
      period[:students].each do |student|
        expect(student[:username]).to match /reviewstudent\d/
      end
    end
  end

  def expect_review_assign(assign)
    expect(assign[:course][:name]).to be_in [
      'Biology 2e Review',
      'Physics with Courseware Review',
      'Sociology with Courseware Review'
    ]
    expect(assign[:task_plans].size).to eq 8
    assign[:task_plans].each do |task_plan|
      match = /(Read|HW) Chapter (\d)/.match task_plan[:title]
      type = match[1] == 'Read' ? 'reading' : 'homework'
      chapter = match[2].to_i
      expect(match).not_to be_nil
      expect(task_plan[:type]).to eq type
      expect(task_plan[:book_locations]).to eq [[chapter, 0], [chapter, 1], [chapter, 2]]
      expect(task_plan[:assigned_to].size).to eq 2
      task_plan[:assigned_to].each do |assigned_to|
        expect(assigned_to[:period][:name]).to be_in ['1st', '2nd']
        expect(Time.parse(assigned_to[:opens_at].to_s)).to be_within(3.weeks).of(Time.now)
        expect(Time.parse(assigned_to[:due_at].to_s)).to be_within(3.weeks).of(Time.now)
      end
    end
  end

  def expect_review_work(work)
    expect(work[:course][:name]).to be_in [
      'Biology 2e Review',
      'Physics with Courseware Review',
      'Sociology with Courseware Review'
    ]
    expect(work[:task_plans].size).to eq 8
    work[:task_plans].each do |task_plan|
      expect(task_plan[:title]).to match /(?:Read|HW) Chapter \d/
      expect(task_plan[:tasks].size).to eq 6
      task_plan[:tasks].each do |task|
        expect(task[:student][:username]).to match /reviewstudent\d/
        expect(task[:progress]).to be_within(0.5).of(0.5)
        next if task[:progress] == 0

        expect(task[:score]).to be_within(0.5).of(0.5)
      end
    end
  end

  it 'calls Demo::All with all the review configs' do
    expect(Demo::All).to receive(:perform_later).exactly(3).times do |args|
      # Users
      expect(args[:users][:teachers]).to eq [username: 'reviewteacher', full_name: 'Review Teacher']
      expect(args[:users][:students].size).to eq 6
      args[:users][:students].each do |student|
        expect(student[:username]).to match /reviewstudent\d/
        expect(student[:full_name]).to match /Review Student\d/
      end

      # Import
      expect_review_import args[:import]

      # Course
      expect_review_course args[:course]

      # Assign
      expect_review_assign args[:assign]

      # Work
      expect_review_work args[:work]

      # Ensure the we return an object similar to what Lev routines usually return
      # Otherwise we'll cause some Exception
      Lev::Routine::Result.new Lev::Outputs.new, Lev::Errors.new
    end

    call
  end

  context 'demo:users' do
    it 'calls Demo::Users with all configs from config/demo/users' do
      expect(Demo::Users).to receive(:perform_later).exactly(9).times do |users:|
        expect(users[:administrators]).to(
          eq [username: 'admin', full_name: 'Administrator User']
        ) if users.has_key? :administrators
        expect(users[:content_analysts].size).to(eq(2)) if users.has_key? :content_analysts
        expect(users[:customer_support].size).to(eq(2)) if users.has_key? :customer_support
        expect(users[:researchers].size).to(eq(2)) if users.has_key? :researchers

        expect(users[:teachers].size).to(
          eq users.has_key?(:students) ? 1 : 8
        ) if users.has_key? :teachers
        expect(users[:students].size).to(
          eq users.has_key?(:teachers) ? 6 : 250
        ) if users.has_key? :students

        Lev::Routine::Result.new Lev::Outputs.new, Lev::Errors.new
      end

      call
    end
  end

  context 'demo:import' do
    it 'calls Demo::Import with all review configs from config/demo/import' do
      expect(Demo::Import).to receive(:perform_later).exactly(3).times do |import:|
        expect_review_import import

        Lev::Routine::Result.new Lev::Outputs.new, Lev::Errors.new
      end

      call
    end
  end

  context 'demo:courses' do
    it 'calls Demo::Course with all review configs from config/demo/course' do
      expect(Demo::Course).to receive(:perform_later).exactly(3).times do |course:|
        expect_review_course course

        Lev::Routine::Result.new Lev::Outputs.new, Lev::Errors.new
      end

      call
    end
  end

  context 'demo:assign' do
    it 'calls Demo::Assign with all review configs from config/demo/assign' do
      expect(Demo::Assign).to receive(:perform_later).exactly(3).times do |assign:|
        expect_review_assign assign

        Lev::Routine::Result.new Lev::Outputs.new, Lev::Errors.new
      end

      call
    end
  end

  context 'demo:work' do
    it 'calls Demo::Work with all review configs from config/demo/work' do
      expect(Demo::Work).to receive(:perform_later).exactly(3).times do |work:|
        expect_review_work work

        Lev::Routine::Result.new Lev::Outputs.new, Lev::Errors.new
      end

      call
    end
  end
end
