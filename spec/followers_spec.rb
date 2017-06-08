require 'spec_helper'

describe Follower do

  let(:follower_json) { {uid: 'social|1'}.to_json }
  let(:follower) { Follower.find_by(organization: 'example', course: 'example/bar', email: 'github|123456').as_json(except: [:created_at, :updated_at]) }

  describe 'POST /courses/:course/followers' do

    context 'when authenticated' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/followers', follower_json }

      it { expect(follower).to json_eq(course: 'example/bar', email: 'github|123456', organization: 'example', uids: ['social|1']) }
    end

    context 'when repeat follower' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/followers', follower_json }
      before { post '/courses/bar/followers', follower_json }

      it { expect(follower['uids'].count).to eq(1) }
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/courses/baz/followers', follower_json }

      it { expect(last_response.body).to eq({message: 'Unauthorized access to example/baz as teacher. Scope is ``'}.to_json) }
    end

    context 'when not authenticated' do
      before { post '/courses/baz/followers', follower_json }

      it { expect(last_response).to_not be_ok }
      it { expect(Follower.find_by(organization: 'example', course: 'example/baz')).to eq nil }
    end

  end

  context 'DELETE /courses/:course/followers/:uid' do
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/bar/followers', follower_json }
    before { delete '/courses/bar/followers/social%7c1' }

    it { expect(follower['uids']).to json_eq [] }
  end

  context 'GET /courses/:course/followers' do
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/bar/followers', follower_json }
    before { get '/courses/bar/followers' }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to json_like({followers: [organization: 'example',
                                                              course: 'example/bar',
                                                              email: 'github|123456',
                                                              uids: ['social|1']]},
                                                 {except: [:created_at, :updated_at]}) }
  end

end
