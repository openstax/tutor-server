# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss
# https://github.com/colszowka/simplecov/issues/369#issuecomment-313493152
RSpec.shared_context "rake" do
  let(:rake)      { Rake.application }
  let(:task_name) { self.class.top_level_description }
  subject(:task)  { rake[task_name] }

  before          { task.reenable }

  def call(*args)
    task.invoke(*args)
  end
end
