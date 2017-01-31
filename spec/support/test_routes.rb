test_routes = Proc.new do
  get 'bad_action' => 'test_exceptions#bad_action'
  get 'url_generation_error' => 'test_exceptions#url_generation_error'
end

Rails.application.routes.send(:eval_block, test_routes)
