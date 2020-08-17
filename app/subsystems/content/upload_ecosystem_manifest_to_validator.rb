class Content::UploadEcosystemManifestToValidator
  lev_routine transaction: :no_transaction

  def exec(ecosystem_or_manifest)
    OpenStax::Validator::V1.upload_ecosystem_manifest ecosystem_or_manifest
  end
end
