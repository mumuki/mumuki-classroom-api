require 'spec_helper'

describe Classroom::Collection::Followers do

  before do
    Classroom::Database.clean!
  end

  describe 'post /courses/:course/followers' do
    let(:follower_json) {{email: 'aguspina87@gmail.com', course: 'bar', uid: 'social|1'}.to_json}

    context 'when authenticated' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/followers', follower_json }

      it { expect(Classroom::Collection::Followers.for('bar').find_by(course: 'example/bar', email: 'aguspina87@gmail.com').to_json).to eq({course: 'example/bar', email: 'aguspina87@gmail.com', uids: ['social|1']}.to_json)}
    end

    context 'when repeat follower' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/bar/followers', follower_json }
      before { post '/courses/bar/followers', follower_json }

      it { expect(Classroom::Collection::Followers.for('bar').find_by(course: 'example/bar', email: 'aguspina87@gmail.com').uids.count).to eq(1)}
    end

    context 'reject unauthorized requests' do
      before { header 'Authorization', build_auth_header('foo/bar') }
      before { post '/courses/baz/followers', follower_json }

      it { expect(last_response.body).to eq({message: 'Unauthorized access to example/baz as teacher. Scope is ``'}.to_json) }
    end

    context 'when not authenticated' do
      let(:follower_json) {{email: 'aguspina87@gmail.com', course: 'bar', uid: 'social|1'}.to_json}
      before { post '/courses/baz/followers', follower_json }

      it { expect(last_response).to_not be_ok }
      it { expect(Classroom::Collection::Followers.for('bar').count).to eq 0 }
    end

  end

  context 'delete /follower' do
    let(:follower_json) {{email: 'aguspina87@gmail.com', course: 'bar', uid: 'social|1'}.to_json}
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/bar/followers', follower_json }
    before { delete '/courses/bar/followers/aguspina87@gmail.com/social%7c1' }

    it { expect(Classroom::Collection::Followers.for('bar').find_by(course: 'example/bar', email: 'aguspina87@gmail.com').uids).to eq([]) }
  end

  context 'get /follower' do
    let(:follower_json) {{email: 'aguspina87@gmail.com', course: 'bar', uid: 'social|1'}.to_json}
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/bar/followers', follower_json }
    before { get '/courses/bar/followers/aguspina87@gmail.com' }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to eq({followers: [{course: 'example/bar', email: 'aguspina87@gmail.com', uids: ['social|1']}]}.to_json)}
  end

end
