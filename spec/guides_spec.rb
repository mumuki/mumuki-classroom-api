require 'spec_helper'

describe Mumuki::Classroom::Guide, organization_workspace: :test do

  def with_course(json)
    {organization: 'example.org', course: 'example.org/foo'}.merge json
  end

  let(:except_fields) { {except: [:created_at, :updated_at]} }

  describe 'get /courses/:course/guides' do
    let(:haskell) { {name: 'haskell', devicon: 'haskell'} }

    let(:guide1) { {slug: 'pdep-utn/bar', name: 'Bar', language: haskell} }
    let(:guide2) { {slug: 'pdep-utn/foo', name: 'Foo', language: haskell} }
    let(:guide3) { {slug: 'pdep-utn/baz', name: 'Baz', language: haskell} }

    context 'when no guides in a course yet' do
      before { header 'Authorization', build_auth_header('*') }
      before { get '/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq guides: [] }
    end

    context 'when guides already exists in a course' do
      before { Mumuki::Classroom::Guide.create! guide1.merge(organization: 'example.org', course: 'example.org/foo') }
      before { Mumuki::Classroom::Guide.create! guide2.merge(organization: 'example.org', course: 'example.org/foo') }
      before { Mumuki::Classroom::Guide.create! guide3.merge(organization: 'example.org', course: 'example.org/bar') }

      before { header 'Authorization', build_auth_header('*') }
      before { get '/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({guides: [with_course(guide1), with_course(guide2)]}, except_fields) }
    end

    context 'when no guides in a course yet' do
      before { header 'Authorization', build_auth_header('*') }
      before { get '/api/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq guides: [] }
    end

    context 'when guides already exists in a course' do
      before { Mumuki::Classroom::Guide.create! guide1.merge(organization: 'example.org', course: 'example.org/foo') }
      before { Mumuki::Classroom::Guide.create! guide2.merge(organization: 'example.org', course: 'example.org/foo') }
      before { Mumuki::Classroom::Guide.create! guide3.merge(organization: 'example.org', course: 'example.org/bar') }

      before { header 'Authorization', build_auth_header('*') }
      before { get '/api/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_like({guides: [with_course(guide1), with_course(guide2)]}, except_fields) }
    end

  end

end
