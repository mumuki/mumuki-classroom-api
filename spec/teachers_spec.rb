require 'spec_helper'

describe Classroom::Collection::Teachers do

  after do
    Classroom::Database.clean!
  end

  describe 'get /courses/:course/teachers' do

    let(:created_at) { 'created_at' }
    before { allow_any_instance_of(BSON::ObjectId).to receive(:generation_time).and_return(created_at) }
    let(:teacher) {{ email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar', social_id: 'auth0|1' }}
    before { header 'Authorization', build_auth_header('*') }

    context 'when there is 1 teacher' do
      before { Classroom::Collection::Teachers.for('foo').insert!(teacher.wrap_json) }
      before { get '/courses/foo/teachers' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq teachers: [teacher.merge(created_at: 'created_at')] }
    end

  end

end
