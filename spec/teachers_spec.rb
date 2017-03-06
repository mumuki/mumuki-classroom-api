require 'spec_helper'

describe Teacher do

  before do
    Classroom::Database.clean!
  end

  let(:except_fields) { {except: [:created_at, :updated_at]} }

  describe 'get /courses/:course/teachers' do

    let(:teacher) { {email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar', uid: 'auth0|1'} }
    before { header 'Authorization', build_auth_header('*') }

    context 'when there is 1 teacher' do
      before { Teacher.create! teacher.merge(organization: 'example', course: 'example/foo') }
      before { get '/courses/foo/teachers' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({teachers: [teacher.merge(organization: 'example', course: 'example/foo')]}, except_fields) }
    end

  end

end
