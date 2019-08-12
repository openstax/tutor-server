require 'rails_helper'

RSpec.describe 'demo', type: :rake do
  include_context 'rake'

  def expect_review_import(import)
    book = import[:book]
    expect(book[:archive_url_base]).to eq 'https://archive.cnx.org/contents/'
    expect(book[:uuid]).to be_in [
      '8d50a0af-948b-4204-a71d-4826cba765b8',
      '405335a3-7cff-4df2-a9ad-29062a4af261',
      '02040312-72c8-441e-a685-20e9333f3e1d'
    ]
    reading_processing_instructions = book[:reading_processing_instructions]
    expect(reading_processing_instructions.size).to be_in [1, 2, 4]
    reading_processing_instructions.each do |reading_processing_instruction|
      expect(reading_processing_instruction[:css]).not_to be_blank
      expect(reading_processing_instruction[:fragments]).to be_a Array
    end

    catalog_offering = import[:catalog_offering]
    expect(catalog_offering[:title]).to be_in [
      'Biology 2e', 'Physics with Courseware', 'Sociology with Courseware'
    ]
    expect(catalog_offering[:salesforce_book_name]).to(
      eq catalog_offering[:title].sub('with', 'w')
    ) if catalog_offering[:title].include? 'with'
    expect(catalog_offering[:appearance_code]).to be_in [
      'biology_2e', 'college_physics', 'intro_sociology'
    ]
  end

  def expect_review_course(course)
    catalog_offering = course[:catalog_offering]
    expect(catalog_offering[:title]).to be_in [
      'Biology 2e', 'Physics with Courseware', 'Sociology with Courseware'
    ]

    course_hash = course[:course]
    expect(course_hash[:name]).to be_in [
      'Biology 2e Review',
      'Physics with Courseware Review',
      'Sociology with Courseware Review'
    ]
    expect(course_hash[:teachers]).to eq [username: 'reviewteacher']
    periods = course_hash[:periods]
    expect(periods.size).to eq 2
    periods.each do |period|
      expect(period[:name]).to be_in ['1st', '2nd']

      students = period[:students]
      expect(students.size).to eq 3
      students.each { |student| expect(student[:username]).to match /reviewstudent\d/ }
    end
  end

  def expect_review_assign(assign)
    course = assign[:course]
    expect(course[:name]).to be_in [
      'Biology 2e Review',
      'Physics with Courseware Review',
      'Sociology with Courseware Review'
    ]

    task_plans = course[:task_plans]
    expect(task_plans.size).to eq 8
    task_plans.each do |task_plan|
      match = /(Read|HW) Chapter (\d)/.match task_plan[:title]
      type = match[1] == 'Read' ? 'reading' : 'homework'
      chapter = match[2].to_i
      expect(match).not_to be_nil
      expect(task_plan[:type]).to eq type
      expect(task_plan[:book_locations]).to eq(
        [ 0, 1, 2 ].map { |section| { chapter: chapter, section: section } }
      )

      assigned_to = task_plan[:assigned_to]
      expect(assigned_to.size).to eq 2
      assigned_to.each do |assigned_to|
        expect(assigned_to[:period][:name]).to be_in ['1st', '2nd']
        expect(Time.parse(assigned_to[:opens_at].to_s)).to be_within(3.weeks).of(Time.now)
        expect(Time.parse(assigned_to[:due_at].to_s)).to be_within(3.weeks).of(Time.now)
      end
    end
  end

  def expect_review_work(work)
    course = work[:course]
    expect(course[:name]).to be_in [
      'Biology 2e Review',
      'Physics with Courseware Review',
      'Sociology with Courseware Review'
    ]

    task_plans = course[:task_plans]
    expect(task_plans.size).to eq 8
    task_plans.each do |task_plan|
      expect(task_plan[:title]).to match /(?:Read|HW) Chapter \d/

      tasks = task_plan[:tasks]
      expect(tasks.size).to eq 6
      tasks.each do |task|
        expect(task[:student][:username]).to match /reviewstudent\d/

        progress = task[:progress]
        expect(progress).to be_within(0.5).of(0.5)
        next if progress == 0

        expect(task[:score]).to be_within(0.5).of(0.5)
      end
    end
  end

  it 'calls Demo::All with all the review configs' do
    expect(Demo::All).to receive(:perform_later).exactly(3).times do |args|
      # Users
      users = args[:users]
      expect(users[:teachers]).to eq [ username: 'reviewteacher', full_name: 'Review Teacher' ]
      expect(users[:students].size).to eq 6
      users[:students].each do |student|
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
        expect(
          users.keys & [
            :administrators,
            :content_analysts,
            :customer_support,
            :researchers,
            :teachers,
            :students
          ]
        ).not_to be_empty

        expect(users[:administrators]).to(
          eq [ username: 'admin', full_name: 'Administrator User' ]
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
