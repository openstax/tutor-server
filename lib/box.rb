module Box
  TMP_FOLDER = 'tmp/box'

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

  def self.with_zip(zip_filename:, files:)
    Dir.mkdir(TMP_FOLDER) unless Dir.exist?(TMP_FOLDER)
    zip_filepath = "#{TMP_FOLDER}/#{zip_filename}"

    begin
      Zip::File.open(zip_filepath, Zip::File::CREATE) do |zipfile|
        files.each { |file| zipfile.add(File.basename(file), file) }
      end

      yield zip_filepath
    ensure
      File.delete(zip_filepath) if File.exist?(zip_filepath)
    end
  end

  def self.upload_files(zip_filename:, files:)
    folderpath = Rails.application.secrets.box['exports_folder']
    folder = client.folder_from_path(folderpath)

    with_zip(zip_filename: zip_filename, files: files) do |zip_filepath|
      client.upload_file(zip_filepath, folder)
    end
  end
end
