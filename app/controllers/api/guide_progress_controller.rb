class Api::GuideProgressController < ApplicationController
  include WithAuthentication

  before_action :protect_guide!, only: [:show, :student_exercise]

  def show
    render json: { guide_progress: GuideProgress.by_slug(slug, env) }
  end

  def student_exercise
    render json: { guide_progress: GuideProgress.exercise_by_student(slug, params[:student_id].to_i, params[:exercise_id].to_i, env) }
  end

  private

end
