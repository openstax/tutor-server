module OpenStax
  module Biglearn
    module V1
    end
  end
end

%w(
  v1/configuration
  v1/pool
  v1/exercise
  v1/fake_client
  v1/real_client
  v1
).each do |f|
  require_relative "./#{f}"
end
