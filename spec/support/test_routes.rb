class TestController < ActionController::Base
  def bad_action
    render text: 'Welcome to my application'
  end
end

test_routes = Proc.new do
  get 'bad_action' => 'test#bad_action'
end

Rails.application.routes.send(:eval_block, test_routes)
