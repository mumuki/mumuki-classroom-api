class Api::CoursesController < ApplicationController
  include WithAuthentication

  before_action :protect_course!, only: :index

  def index
    grants = @permissions.to_s.gsub(/[:]/, '|')
    render json: { guides_progress: GuideProgress.by_course(grants, env) }
  end


end
