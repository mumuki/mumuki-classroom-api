class HomeController < ApplicationController
  def index
    render json: { great: 'Hello!' }
  end
end
