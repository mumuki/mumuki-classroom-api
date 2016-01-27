class Api::CoursesController < ApplicationController
  include WithAuthentication

  before_action :protect_course!, only: :index

  def index
    render json: { guides_progress: GuideProgress.by_slug('course', slug, env) }
  end


end
