module WebviewHelper

  # Generates data for the FE to read as it boots up
  def bootstrap_data
    Api::V1::UserBootstrapDataRepresenter.new(current_user).as_json
  end

end
