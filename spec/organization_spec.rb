require 'spec_helper'

describe 'organizations' do

  let(:organization_json) {{
    name: 'test',
    book: 'mumuki/mumuki-libro-programacion',
    profile: {
      logo_url: 'https://mumuki.io/logo',
      terms_of_service: 'tos',
      description: '¡Hola! Aprendamos sobre las bases de la programación',
      community_link: 'https://community.com',
      contact_email: 'info@mumuki.org',
      locale: 'es'
    },
    theme: {
      theme_stylesheet: 'stylesheets/test-1.css',
      extension_javascript: 'javascripts/test-1.js'
    },
    settings: {
      public: false,
      raise_hand_enabled: false,
      login_methods: [ 'user_pass' ]
    }
  }}

  describe 'OrganizationCreated' do
    context 'Success' do
      before {Organization.create! organization_json}
      it {expect(Organization.first.as_json).to json_like(organization_json,
                                                  except: [:created_at, :updated_at, :_id, :id])}

    end

  end

end
