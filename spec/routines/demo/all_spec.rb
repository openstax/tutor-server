require 'rails_helper'

RSpec.describe Demo::All, type: :routine do
  let(:config_base_dir) { File.join Rails.root, 'spec', 'fixtures', 'demo' }
  let(:config_types)    { [ 'users', 'import', 'course', 'assign', 'work' ] }
  let(:config)          do
    {}.tap do |config|
      [config_types].flatten.each do |type|
        type_string = type.to_s
        hash = YAML.load_file File.join(config_base_dir, type_string, 'review', 'apush.yml')
        representer_class = Api::V1::Demo.const_get(type_string.capitalize)::Representer
        config[type.to_sym] = representer_class.new(hash).to_hash.deep_symbolize_keys
      end
    end
  end
  let(:result)          { described_class.call config }

  it 'calls other demo routines with the correct arguments' do
    expect_any_instance_of(Demo::Users).to receive(:call).with(config.slice :users).and_return(
      Lev::Routine::Result.new(
        Lev::Outputs.new(users: User::Models::Profile.new(id: 21)), Lev::Errors.new
      )
    )

    expect_any_instance_of(Demo::Import).to receive(:call).with(
      config.slice :import
    ).and_return Lev::Routine::Result.new(
      Lev::Outputs.new(catalog_offering: Catalog::Models::Offering.new(id: 42)), Lev::Errors.new
    )

    expected_course_config = config[:course]
    expected_course_config[:catalog_offering][:id] = 42
    expect_any_instance_of(Demo::Course).to receive(:call).with(
      course: expected_course_config
    ).and_return Lev::Routine::Result.new(
      Lev::Outputs.new(course: CourseProfile::Models::Course.new(id: 84)), Lev::Errors.new
    )

    expected_assign_config = config[:assign]
    expected_assign_config[:course][:id] = 84
    expect_any_instance_of(Demo::Assign).to receive(:call).with(
      assign: expected_assign_config
    ).and_return Lev::Routine::Result.new(
      Lev::Outputs.new(task_plans: [Tasks::Models::TaskPlan.new(id: 168)]), Lev::Errors.new
    )

    expected_work_config = config[:work]
    expected_work_config[:course][:id] = 84
    expect(Demo::Work).to receive(:perform_later).with(
      work: expected_work_config
    ).and_return Lev::Routine::Result.new(Lev::Outputs.new, Lev::Errors.new)

    expect(result.errors).to be_empty
  end
end
