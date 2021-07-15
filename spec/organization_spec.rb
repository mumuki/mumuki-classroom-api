require 'spec_helper'

describe 'organizations' do

  describe(:model) do
    it "supports reading organizations from database" do
      organization = create :organization, locale: 'es', name: 'an.es.organization'

      expect(organization.name).to eq 'an.es.organization'
      expect(organization.locale).to eq 'es'
      expect(organization.profile.locale).to eq 'es'
    end

    it "supports updating as in import" do
      organization = create :organization, locale: 'en', name: 'an.es.organization'

      expect(organization.name).to eq 'an.es.organization'
      expect(organization.locale).to eq 'en'
      expect(organization.profile.locale).to eq 'en'
    end

  end

  let(:organization_resource_h) {{
    name: 'test',
    book: 'mumuki/mumuki-libro-programacion',
    profile: {
      logo_url: 'https://mumuki.io/logo',
      terms_of_service: 'tos',
      description: '¡Hola! Aprendamos sobre las bases de la programación',
      community_link: 'https://community.com',
      contact_email: 'info@mumuki.org',
      locale: 'es',
      time_zone: 'Los Angeles',
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
      before { create :book, slug: 'mumuki/mumuki-libro-programacion' }
      before { Organization.import_from_resource_h! organization_resource_h }
      it {expect(Organization.first.to_resource_h).to json_like(organization_resource_h, except: [:created_at, :updated_at, :_id, :id])}
    end
  end
end
