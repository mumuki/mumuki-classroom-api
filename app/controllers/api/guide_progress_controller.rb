class Api::GuideProgressController < ApplicationController

  def show
    result = GuideProgress.by_slug params[:slug], env
    render json: { guide_progress: result.as_json }
  end

end
