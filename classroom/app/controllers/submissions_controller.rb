class SubmissionsController < ApplicationController
  def create
    Submission.insert! params[:submission].as_json, request
  end
end
