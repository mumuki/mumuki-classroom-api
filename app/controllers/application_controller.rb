class ApplicationController < ActionController::API
  before_action :set_mongo_connection
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers



  def cors_set_access_control_headers
    default_headers
  end

  def cors_preflight_check
    if request.method == 'OPTIONS'
      default_headers
      render :text => '', :content_type => 'text/plain'
    end
  end

  private

  def set_mongo_connection
    tenant = request.subdomain.present?? request.subdomain : 'central'
    request.env['mongo_client'] = Mongo::Client.new([ '127.0.0.1:27017' ], database: tenant)
  end

  def default_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Credentials'] = 'true'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

end
