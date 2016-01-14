class SubmissionsController < ApplicationController
  include WithParameterConverter

  def create
    if Student.exists? params[:submission][:submitter][:id], request
      Submission.insert! convert(params[:submission]), request
    else
      render json: { error: I18n.t(:student_not_found) }, status: :not_found
    end
  end

end
