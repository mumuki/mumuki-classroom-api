class Events::SubmissionsController < ApplicationController
  include WithParameterConverter

  def create
    puts params
    ProgressGuide.update! convert(params[:submission]), request.env
  end

end
