module WithAuthentication

  def permissions
    @permissions ||= parse_token.permissions 'classroom'
  rescue Mumukit::Auth::InvalidTokenError
    render json: { status: :errored }, status: 400
  end

  def parse_token
    token = Mumukit::Auth::Token.decode_header(authorization_header)
    token.tap &:verify_client!
  end

  def protect!(course_slug=nil)
    @permissions ||= parse_token.permissions 'classroom'
    @permissions.protect!(course_slug || slug(:course))
  rescue Mumukit::Auth::InvalidTokenError
    render json: { status: :errored }, status: 400
  rescue Mumukit::Auth::UnauthorizedAccessError => e
    render json: { status: :unauthorized, message: e.message }, status: 403
  end

  def authorization_header
    env['HTTP_AUTHORIZATION']
  end

  def slug(type)
    "#{org}/#{params[type]}"
  end

  def org
   params[:org]
  end

end
