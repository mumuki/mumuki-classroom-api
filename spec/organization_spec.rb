require 'spec_helper'

describe 'organizations' do

  describe(:model) do
    it do
      Organization.create!(
        profile: Mumukit::Platform::Organization::Profile.new(locale: 'es'),
        name: 'an.es.organization')

      expect(Organization.find_by(name: 'an.es.organization').profile.locale).to eq 'es'
    end

    it { Organization.create!(locale: 'es') }
    it { Organization.create!(profile: Mumukit::Platform::Organization::Profile.new(locale: 'es')) }

    it { expect(Organization.new(name: 'the.name').name).to eq 'the.name' }
    it { expect(Organization.new(locale: 'es').locale).to eq 'es' }
    it { expect(Organization.new(profile: {locale: 'es'}).locale).to eq 'es' }
    it { expect(Organization.new(profile: Mumukit::Platform::Organization::Profile.new(locale: 'es')).locale).to eq 'es' }
    it do
      organization = Organization.new
      expect(organization.profile).to eq organization.profile
    end
  end

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
