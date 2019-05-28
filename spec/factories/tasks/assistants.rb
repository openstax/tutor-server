FactoryBot.define do
  factory :tasks_assistant, class: '::Tasks::Models::Assistant' do
    name            { Faker::Name.name }
    code_class_name { Faker::App.name.gsub(/[ -]/, '') }

    after(:build) do |assistant, evaluator|

      begin
        # define the code class so it exists; check to make sure
        # it doesn't exist first
        klass = Module.const_get(assistant.code_class_name)
      rescue NameError
        # doesn't exist, make it
        Object.const_set(assistant.code_class_name, Class.new do
          def self.schema
            "{}"
          end

          def build_tasks
            roles.map { build_task(type: :external, default_title: 'Dummy') }
          end
        end)
      end

    end
  end
end
