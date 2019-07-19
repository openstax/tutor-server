# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss
# https://github.com/colszowka/simplecov/issues/369#issuecomment-313493152
RSpec.shared_context "rake" do
  let(:application) { Rake.application }
  subject(:task)    do
    task = nil
    self.class.ancestors.each do |ancestor|
      next unless ancestor.respond_to? :description

      begin
        task = application[ancestor.description]

        break
      rescue RuntimeError # Don't know how to build task
      end
    end
    task
  end

  before { task.reenable }

  def call(*args)
    task.invoke(*args)
  end
end
