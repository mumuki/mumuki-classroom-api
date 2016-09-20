class Classroom::Atheneum
  class << self
    def organization
      RestClient::Resource
        .new(organization_url, client_id, client_secret)
        .get
    end

    def organization_json
      JSON.parse(organization)
    end

    def locale
      organization_json['organization']['locale']
    end

    def organization_url
      "#{Classroom::Database.organization}.#{Mumukit::Service::Env.atheneum_url}/api/organizations"
    end

    def client_id
      Mumukit::Service::Env.atheneum_client_id
    end

    def client_secret
      Mumukit::Service::Env.atheneum_client_secret
    end
  end
end
