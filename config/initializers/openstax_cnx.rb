secrets = Rails.application.secrets['openstax']['cnx']

OpenStax::Cnx::V1.archive_url_base = secrets['archive_url']
