require 'spec_helper'

describe Teacher do

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

  describe 'post /courses/:course/teacher' do

    let(:teacher) { {email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar'} }

    context 'when success' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/foo/teacher', teacher.to_json }

      it { expect(last_response).to be_ok }
      it { expect(Teacher.count).to eq 1 }
      it { expect(Teacher.first.as_json).to json_like(teacher.merge(organization: 'example', course: 'example/foo', uid: 'foobar@gmail.com'), except_fields) }
    end

    context 'when no permissions' do
      before { header 'Authorization', build_auth_header('') }
      before { post '/courses/foo/teacher', teacher.to_json }

      it { expect(last_response).to_not be_ok }
      it { expect(Teacher.count).to eq 0 }
    end

  end

end
