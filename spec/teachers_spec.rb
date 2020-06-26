require 'spec_helper'

describe Mumuki::Classroom::Teacher, workspaces: [:organization] do

  let(:except_fields) { {except: [:created_at, :updated_at]} }

  let(:response) { struct JSON.parse(last_response.body) }

  describe 'get /courses/:course/teachers' do

    let(:teacher) { {email: 'foobar@gmail.com', first_name: 'foo', last_name: 'bar', uid: 'auth0|1'} }
    before { header 'Authorization', build_auth_header('*') }

    context 'when there is 1 teacher' do
      before { Mumuki::Classroom::Teacher.create! teacher.merge(organization: 'example.org', course: 'example.org/foo') }
      before { get '/courses/foo/teachers' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({teachers: [teacher.merge(organization: 'example.org', course: 'example.org/foo')]}, except_fields) }
    end

  end

  describe 'post /courses/:course/teachers' do

    let(:teacher) { {email: 'foobar@gmail.com', first_name: 'Foo', last_name: 'Bar'} }
    let(:created_user) { User.locate! teacher[:email] }

    context 'when success' do
      before { header 'Authorization', build_auth_header('*') }
      before { post '/courses/foo/teachers', teacher.to_json }

      it { expect(last_response).to be_ok }
      it { expect(Mumuki::Classroom::Teacher.count).to eq 1 }
      it { expect(Mumuki::Classroom::Teacher.first.as_json).to json_like(teacher.merge(organization: 'example.org', course: 'example.org/foo', uid: 'foobar@gmail.com'), except_fields) }
      it { expect(created_user.first_name).to eq created_user.verified_first_name }
      it { expect(created_user.last_name).to eq created_user.verified_last_name }
    end

    context 'when no permissions' do
      before { header 'Authorization', build_auth_header('') }
      before { post '/courses/foo/teachers', teacher.to_json }

      it { expect(last_response).to_not be_ok }
      it { expect(Mumuki::Classroom::Teacher.count).to eq 0 }
    end

  end

end
