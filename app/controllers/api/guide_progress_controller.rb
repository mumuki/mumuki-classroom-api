class Api::GuideProgressController < ApplicationController
  include WithAuthentication

  before_action :protect_guide!, only: :show

  def show
    result = GuideProgress.by_slug slug, env
    render json: { guide_progress: result.as_json }
  end

  private

end
