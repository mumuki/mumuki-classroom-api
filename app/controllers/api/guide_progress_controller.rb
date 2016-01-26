class Api::GuideProgressController < ApplicationController
  include WithAuthentication

  before_action :authenticate, only: :show

  def show
    result = GuideProgress.by_slug "#{params[:org]}/#{params[:repo]}", env
    render json: { guide_progress: result.as_json }
  end

end
