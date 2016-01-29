class Api::CoursesController < ApplicationController
  include WithAuthentication

  before_action :protect!, only: :show
  before_action :permissions, only: :index


  def index
    grants = @permissions.to_s.gsub(/[:]/, '|').gsub(/[*]/, '.*')
    render json: { courses: Course.all(grants, env) }
  end

  def show
    render json: { course_guides: GuideProgress.by_course(slug(:course), env) }
  end


end
