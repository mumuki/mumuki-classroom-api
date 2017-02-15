require 'spec_helper'

describe Classroom::Collection::Teachers do

  before do
    Classroom::Database.clean!
  end

  describe 'get /courses/:course/teachers' do

    let(:created_at) { 'created_at' }
    before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
    let(:teacher) { {email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar', uid: 'auth0|1'} }
    before { header 'Authorization', build_auth_header('*') }

    context 'when there is 1 teacher' do
      before { Classroom::Collection::Teachers.for('example', 'foo').insert! teacher }
      before { get '/courses/foo/teachers' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to eq({teachers: [{organization: 'example', course: 'example/foo'}.merge(teacher).merge(created_at: 'created_at')]}.to_json) }
    end

  end

end
