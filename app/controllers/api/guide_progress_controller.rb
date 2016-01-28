class Api::GuideProgressController < ApplicationController
  include WithAuthentication

  before_action :permissions, only: [:show, :student_exercise]

  def show
    guide = GuideProgress.by_slug(slug(:repo), env).first
    @permissions.protect! guide['course']['slug']
    render json: { guide_progress: guide}
  end

  def student_exercise
    render json: { guide_progress: GuideProgress.exercise_by_student(slug(:repo), params[:student_id].to_i, params[:exercise_id].to_i, env) }
  end

  private

end
