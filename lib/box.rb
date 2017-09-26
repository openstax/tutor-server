module Box
  def self.client
    RequestStore.store[:box_client] ||= begin
      box_secrets = Rails.application.secrets.box

      enterprise_token = Boxr::get_enterprise_token(
        client_id: box_secrets['client_id'],
        client_secret: box_secrets['client_secret'],
        public_key_id: box_secrets['jwt_public_key_id'],
        private_key: box_secrets['jwt_private_key'],
        private_key_password: box_secrets['jwt_private_key_password'],
        enterprise_id: box_secrets['enterprise_id']
      )

      Boxr::Client.new enterprise_token['access_token']
    end
  end

  def self.upload_file(filename)
    foldername = Rails.application.secrets.box['exports_folder']
    folder = client.folder_from_path(foldername)
    client.upload_file(filename, folder)
  end
end
