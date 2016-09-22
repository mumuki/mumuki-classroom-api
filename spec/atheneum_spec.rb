require 'spec_helper'

describe Classroom::Atheneum do

  after do
    Classroom::Database.clean!
  end

  describe 'get /organization' do
    let(:org_json) { {organization: {locale: 'es', name: 'example'}}.to_json}
    before { get '/organization'}

    it { expect(last_response.body).to eq(org_json)}
  end
end
