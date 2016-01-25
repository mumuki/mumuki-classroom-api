class Events::SubmissionsController < ApplicationController
  include WithParameterConverter

  def create
    GuideProgress.update! convert(params[:submission]), request.env
  end

end
