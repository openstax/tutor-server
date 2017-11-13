module Box
  def self.client
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

  def self.zip_file(filepath)
    "#{filepath.gsub(File.extname(filepath), '')}.zip".tap do |zip_filepath|
      Zip::File.open(zip_filepath, Zip::File::CREATE) do |zipfile|
        zipfile.add(File.basename(filepath), filepath)
      end
    end
  end

  def self.upload_file(filepath, zip = true)
    filepath = zip_file(filepath) if zip

    folderpath = Rails.application.secrets.box['exports_folder']
    folder = client.folder_from_path(folderpath)
    client.upload_file(filepath, folder)
  end
end
