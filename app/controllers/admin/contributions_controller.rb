# frozen_string_literal: true

class Admin::ContributionsController < Admin::BaseController
  layout 'catarse_bootstrap'

  # gateway_refund is used as external action in catarse.js
  def gateway_refund
    resource.direct_refund
    respond_to do |format|
      format.html do
        return redirect_to admin_contributions_path(params[:local_params])
      end
      format.json do
        return render json: []
      end
    end
  end

  protected

  def resource
    ContributionDetail.find_by_id params[:id]
  end
end
