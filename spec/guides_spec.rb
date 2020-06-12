require 'spec_helper'

describe Guide, workspaces: [:organization, :courses] do

  let(:response) { JSON.parse last_response.body, object_class: OpenStruct }

  describe 'GET http://localmumuki.io/:organization/courses/:course/guides' do
    before { header 'Authorization', build_auth_header('*') }
    before { get '/courses/foo/guides' }

    it { expect(last_response).to be_ok }
    it { expect(response.guides.count).to eq 4 }
    it { expect(response.guides.first.slug).to eq 'original/guide1' }
    it { expect(response.guides.second.slug).to eq 'original/guide2' }
    it { expect(response.guides.third.slug).to eq 'original/guide3' }
    it { expect(response.guides.last.slug).to eq 'original/guide4' }
  end


  describe 'GET http://localmumuki.io/:organization/api/courses/:course/guides' do
    before { header 'Authorization', build_auth_header('*') }
    before { get '/api/courses/foo/guides' }

    it { expect(last_response).to be_ok }
    it { expect(response.guides.count).to eq 4 }
    it { expect(response.guides.first.slug).to eq 'original/guide1' }
    it { expect(response.guides.second.slug).to eq 'original/guide2' }
    it { expect(response.guides.third.slug).to eq 'original/guide3' }
    it { expect(response.guides.last.slug).to eq 'original/guide4' }
  end

  describe 'GET http://localmumuki.io/guides/:organization/:repository' do
    before { header 'Authorization', build_auth_header('*') }

    context 'when guide has usage in current organization' do
      before { get '/guides/original/guide1' }

      it { expect(last_response).to be_ok }
      it { expect(response.guide.slug).to eq 'original/guide1' }
    end

    context 'when guide has not got usage in current organization' do
      before { create :guide, slug: 'foo/bar' }
      before { get '/guides/foo/bar' }

      it { expect(last_response).to_not be_ok }
      it { expect(response.message).to eq "Couldn't find Guide with slug: foo/bar" }
    end

  end
end
