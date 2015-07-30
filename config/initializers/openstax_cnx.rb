secrets = Rails.application.secrets['openstax']['cnx']

OpenStax::Cnx::V1.set_archive_url_base url: secrets['archive_url']
