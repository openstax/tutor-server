module Api::V1
  module Admin
    class UserSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter

      collection :items, inherit: true, extend: Api::V1::Admin::UserRepresenter

    end
  end
end
