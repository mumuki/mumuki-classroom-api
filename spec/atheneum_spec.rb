require 'spec_helper'

describe Classroom::Atheneum do

  after do
    Classroom::Database.clean!
  end

  describe 'get /organization' do
    let(:org_json) { {organization: {locale: 'es', name: 'example'}}.to_json}
    context 'do not fetch atheneum' do
      before { expect(RestClient::Resource).to_not receive(:get) }
      before { get '/organization'}

      it { expect(last_response.body).to eq(org_json)}
    end

    context 'fetch atheneum' do
      before { Classroom::Collection::Organizations.delete_one(name: 'example') }
      before { expect_any_instance_of(RestClient::Resource).to receive(:get).and_return(org_json) }
      before { get '/organization'}

      it { expect(last_response.body).to eq(org_json)}
    end
  end
end
