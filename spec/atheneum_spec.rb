require 'spec_helper'

describe Classroom::Atheneum do

  after do
    Classroom::Database.clean!
  end

  describe 'get /organization' do
    let(:org_json) { {organization: {id: 1}}.to_json}
    let(:rest_mock) { double('rest_mock') }

    before { expect_any_instance_of(RestClient::Resource).to receive(:get).and_return(org_json) }
    before { get '/organization'}

    it { expect(last_response.body).to eq(org_json)}
  end
end
