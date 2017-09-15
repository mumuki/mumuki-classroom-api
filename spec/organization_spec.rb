require 'spec_helper'

describe 'organizations' do

  let(:organization_json) {{
    'logo_url': 'https://mumuki.io/logo',
    'theme_stylesheet_url': 'stylesheets/test-1.css',
    'extension_javascript_url': 'javascripts/test-1.js',
    'terms_of_service': 'tos',
    'name': 'test',
    'description': '¡Hola! Aprendamos sobre las bases de la programación',
    'community_link': 'https://community.com',
    'raise_hand_enabled': false,
    'public': false,
    'contact_email': 'info@mumuki.org',
    'books': [
      'mumuki/mumuki-libro-programacion'
    ],
    'locale': 'es',
    'login_methods': [
      'user_pass'
    ]
  }}

  describe 'OrganizationCreated' do
    context 'Success' do
      before {Organization.create! organization_json}
      it {expect(Organization.first.as_json).to json_like(organization_json,
                                                  except: [:created_at, :updated_at, :_id, :id])}

    end

  end

end
