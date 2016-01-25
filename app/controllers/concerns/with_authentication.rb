module WithAuthentication

  def authenticate
    token = Mumukit::Auth::Token.decode_header(authorization_header)
    token.verify_client!
  end

  def authorization_header
    env['HTTP_AUTHORIZATION']
  end

end
