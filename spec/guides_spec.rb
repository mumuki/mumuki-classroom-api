require 'spec_helper'

describe Classroom::Collection::Guides do

  def with_course(json)
    {organization: 'example', course: 'example/foo'}.merge json
  end

  before do
    Classroom::Database.clean!
  end

  describe 'get /courses/:course/guides' do
    let(:haskell) { {name: 'haskell', devicon: 'haskell'} }
    let(:guide1) { {slug: 'pdep-utn/foo', name: 'Foo', language: haskell} }
    let(:guide2) { {slug: 'pdep-utn/bar', name: 'Bar', language: haskell} }
    let(:guide3) { {slug: 'pdep-utn/baz', name: 'Baz', language: haskell} }


    context 'when no guides in a course yet' do
      before { header 'Authorization', build_auth_header('*') }
      before { get '/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq guides: [] }
    end

    context 'when guides already exists in a course' do
      before { Classroom::Collection::Guides.for('example', 'foo').insert!(guide1) }
      before { Classroom::Collection::Guides.for('example', 'foo').insert!(guide2) }
      before { Classroom::Collection::Guides.for('example', 'bar').insert!(guide3) }
      before { header 'Authorization', build_auth_header('*') }
      before { get '/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to eq({guides: [with_course(guide1), with_course(guide2)]}.to_json) }
    end

    context 'when no guides in a course yet' do
      before { header 'Authorization', build_mumuki_auth_header('*') }
      before { get '/api/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq guides: [] }
    end

    context 'when guides already exists in a course' do
      before { Classroom::Collection::Guides.for('example', 'foo').insert!(guide1) }
      before { Classroom::Collection::Guides.for('example', 'foo').insert!(guide2) }
      before { Classroom::Collection::Guides.for('example', 'bar').insert!(guide3) }
      before { header 'Authorization', build_mumuki_auth_header('*') }
      before { get '/api/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to eq({guides: [with_course(guide1), with_course(guide2)]}.to_json) }
    end

  end

end
