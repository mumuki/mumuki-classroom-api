class Api::GuideProgressController < ApplicationController

  def show
    result = GuideProgress.by_id params[:id].to_i, env
    render json: { guide_progress: result.as_json }
  end

end
