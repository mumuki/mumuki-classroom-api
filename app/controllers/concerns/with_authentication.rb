module WithAuthentication

  def protect_course!
    protect! 'classroom'
  end

  def protect_guide!
    protect! 'bibliotheca'
  end

  def protect!(type)
    @permissions ||= parse_token.permissions type
    @permissions.protect! slug if type == 'bibliotheca'
  rescue Mumukit::Auth::UnauthorizedAccessError => e
    render json: { status: :unauthorized, message: e.message }, status: 403
  rescue Mumukit::Auth::InvalidTokenError
    render json: { status: :errored }, status: 400
  end

  def parse_token
    token = Mumukit::Auth::Token.decode_header(authorization_header)
    token.tap &:verify_client!
  end

  def authorization_header
    env['HTTP_AUTHORIZATION']
  end

  def slug
    "#{params[:org]}/#{params[:repo]}"
  end


end
