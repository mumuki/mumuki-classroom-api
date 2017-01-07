require 'spec_helper'

describe Classroom::Collection::Guides do

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
      before { Classroom::Collection::Guides.for('foo').insert!(guide1.wrap_json) }
      before { Classroom::Collection::Guides.for('foo').insert!(guide2.wrap_json) }
      before { Classroom::Collection::Guides.for('bar').insert!(guide3.wrap_json) }
      before { header 'Authorization', build_auth_header('*') }
      before { get '/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq guides: [guide1, guide2] }
    end

    context 'when no guides in a course yet' do
      before { header 'Authorization', build_mumuki_auth_header('*') }
      before { get '/api/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq guides: [] }
    end

    context 'when guides already exists in a course' do
      before { Classroom::Collection::Guides.for('foo').insert!(guide1.wrap_json) }
      before { Classroom::Collection::Guides.for('foo').insert!(guide2.wrap_json) }
      before { Classroom::Collection::Guides.for('bar').insert!(guide3.wrap_json) }
      before { header 'Authorization', build_mumuki_auth_header('*') }
      before { get '/api/courses/foo/guides' }

      it { expect(last_response).to be_ok }
      it { expect(last_response.body).to json_eq guides: [guide1, guide2] }
    end

  end

end
