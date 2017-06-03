class Api::V1::TermsController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Info about which terms have been signed and endpoints for signing'
    description <<-EOS
    EOS
  end

  api :GET, '/terms', 'Returns info on terms applicable to current user'
  description <<-EOS
    Output looks like:

    ```
    [
      {
        id: 42,
        name: "general_terms_of_use",
        title: "Terms of Use",
        content: "bunch of HTML",
        version: 2,
        is_signed: false,
        has_signed_before: true,
        is_proxy_signed: false
      },
      ...
    ]
    ```
  EOS
  def index
    if current_human_user.nil? || current_human_user.is_anonymous?
      head :forbidden
    else
      respond_to do |format|
        format.json { render json: GetUserTermsInfos[current_human_user].to_json }
      end
    end
  end

  api :PUT, '/terms/:ids', 'Signs the identified terms for the current user'
  description <<-EOS
    :ids should be a comma-separated list of contract IDs that the user signed
  EOS
  def update
    if current_human_user.nil? || current_human_user.is_anonymous?
      head :forbidden
    else
      ids.split(',').map(&:strip).each do |id|
        signature = FinePrint.sign_contract(current_user.to_model, id)
        if signature && signature.errors.any?
          render_api_errors(signature.errors)
          return
        end
      end

      head :success
    end
  end

end
