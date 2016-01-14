class ApplicationController < ActionController::API
  before_action :set_mongo_connection



  private

  def set_mongo_connection
    tenant = request.subdomain.present?? request.subdomain : 'central'
    request.env['mongo_client'] = Mongo::Client.new([ '127.0.0.1:27017' ], database: tenant)
  end

end
