module WithAuthentication

  def permissions
    token = Mumukit::Auth::Token.decode_header(authorization_header)
    token.verify_client!
    @permissions ||= token.permissions 'classroom'
  end

  def protect!
    permissions.protect! slug
  end

  def authorization_header
    env['HTTP_AUTHORIZATION']
  end

  def slug
    "#{params[:org]}/#{params[:repo]}"
  end


end
