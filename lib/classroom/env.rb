module Classroom::Env
  class << self
    def atheneum_url
      ENV['MUMUKI_ATHENEUM_URL']
    end

    def atheneum_client_secret
      ENV['MUMUKI_ATHENEUM_CLIENT_SECRET']
    end

    def atheneum_client_id
      ENV['MUMUKI_ATHENEUM_CLIENT_ID']
    end
  end
end
