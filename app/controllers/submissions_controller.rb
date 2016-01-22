class SubmissionsController < ApplicationController
  include WithParameterConverter

  def create
    if Student.exists? params[:submission][:submitter][:id], request.env
      Submission.insert! convert(params[:submission]), request.env
    else
      render json: { error: I18n.t(:student_not_found) }, status: :not_found
    end
  end

end
