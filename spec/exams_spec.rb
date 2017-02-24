require 'spec_helper'

describe Classroom::Collection::Exams do

  after do
    Classroom::Database.clean!
  end

  describe 'get /courses/:course/exams' do
    let(:exam_json) { {slug: 'foo/bar', start_time: 'today', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo'} }
    let(:response_json) { JSON.parse(last_response.body).deep_symbolize_keys }

    before { header 'Authorization', build_auth_header('*') }
    before { Classroom::Collection::Exams.for('example', 'foo').insert! exam_json.wrap_json }
    before { get '/courses/foo/exams' }

    it { expect(last_response.body).to be_truthy }
    it { expect(response_json[:exams].first[:id]).to be_truthy }
    it { expect(response_json[:exams].first.except(:id).to_json).to eq({organization: 'example', course: 'example/foo'}.merge(exam_json).to_json) }

  end

  describe 'post /courses/:course/exams' do
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: []}.stringify_keys }
    let(:result_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: []}.stringify_keys }
    let(:exam_fetched) { Classroom::Collection::Exams.for('example', 'foo').where({}).as_json[:exams].first }

    before { expect(Mumukit::Nuntius::EventPublisher).to receive(:publish).with('UpsertExam', exam_json.merge('tenant' => 'example', 'id' => instance_of(String))) }
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/foo/exams', exam_json.to_json }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to json_like({status: 'created'}, {except: :id}) }
    it { expect(Classroom::Collection::Exams.for('example', 'foo').count).to eq 1 }
    it { expect(exam_fetched['id']).to be_truthy }
    it { expect(exam_fetched.except('id')).to json_eq({organization: 'example', course: 'example/foo'}.merge(result_json)) }

  end

  describe 'post /api/courses/:course/exams' do
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: []}.stringify_keys }
    let(:result_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: []}.stringify_keys }
    let(:exam_fetched) { Classroom::Collection::Exams.for('example', 'foo').all.as_json[:exams].first }

    before { expect(Mumukit::Nuntius::EventPublisher).to receive(:publish).with('UpsertExam', exam_json.merge('tenant' => 'example', 'id' => kind_of(String))) }
    before { header 'Authorization', build_mumuki_auth_header('*') }
    before { post '/api/courses/foo/exams', exam_json.to_json }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to json_like({status: 'created'}, {except: :id}) }
    it { expect(Classroom::Collection::Exams.for('example', 'foo').count).to eq 1 }
    it { expect(exam_fetched['id']).to be_truthy }
    it { expect(exam_fetched.except('id')).to json_eq({organization: 'example', course: 'example/foo'}.merge(result_json)) }

  end

  describe 'get /courses/:course/exams/:exam_id' do
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: []} }
    let(:exam_id) { Classroom::Collection::Exams.for('example', 'foo').insert!(exam_json.wrap_json)[:id] }
    let(:response_json) { JSON.parse(last_response.body).deep_symbolize_keys }

    before { header 'Authorization', build_auth_header('*') }
    before { get "/courses/foo/exams/#{exam_id}", exam_json.to_json }

    it { expect(response_json[:id]).to be_truthy }
    it { expect(response_json.except(:id)).to eq(exam_json.merge(organization: 'example', course: 'example/foo')) }
  end

  describe 'put /courses/:course/exams/:exam' do
    let!(:id) { Classroom::Collection::Exams.for('example', 'foo').insert! exam_json.wrap_json }
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: ['auth0|234567', 'auth0|345678']}.stringify_keys }
    let(:exam_json2) { exam_json.merge(uids: ['auth0|123456'], id: id[:id]).stringify_keys }
    let(:result_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: ['auth0|123456']}.stringify_keys }
    let(:exam_fetched) { Classroom::Collection::Exams.for('example', 'foo').where({}).as_json[:exams].first }

    context 'when existing exam' do
      before { expect(Mumukit::Nuntius::EventPublisher).to receive(:publish).exactly(1).times }
      before { header 'Authorization', build_auth_header('*') }
      before { put "/courses/foo/exams/#{id[:id]}", exam_json2.to_json }

      it { expect(last_response.body).to be_truthy }
      it { expect(last_response.body).to json_like({status: 'updated'}, {except: :id}) }
      it { expect(Classroom::Collection::Exams.for('example', 'foo').count).to eq 1 }
      it { expect(exam_fetched['id']).to eq(id[:id]) }
      it { expect(exam_fetched.except('id').to_json).to json_eq result_json.merge(organization: 'example', course: 'example/foo') }
    end

    context 'when no existing exam' do
      let(:exam_json2) { exam_json.merge(uids: ['auth0|123456'], id: '123').stringify_keys }
      before { header 'Authorization', build_auth_header('*') }
      it { expect { Classroom::Collection::Exams.for('example', 'foo').update! '123', exam_json2 }.to raise_error(Classroom::ExamExistsError) }
    end

  end

  describe 'post /api/courses/:course/exams/:exam/students/:uid' do
    let!(:id) { Classroom::Collection::Exams.for('example', 'foo').insert! exam_json.wrap_json }
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: ['auth0|234567', 'auth0|345678']}.stringify_keys }
    let(:exam_fetched) { Classroom::Collection::Exams.for('example', 'foo').where({}).as_json[:exams].first }

    context 'when existing exam' do
      before { expect(Mumukit::Nuntius::EventPublisher).to receive(:publish).exactly(1).times }
      before { header 'Authorization', build_mumuki_auth_header('*') }
      before { post "/api/courses/foo/exams/#{id[:id]}/students/agus@mumuki.org" }

      it { expect(last_response.body).to be_truthy }
      it { expect(last_response.body).to json_like({status: 'updated'}, {except: :id}) }
      it { expect(Classroom::Collection::Exams.for('example', 'foo').count).to eq 1 }
      it { expect(exam_fetched['uids'].last).to eq('agus@mumuki.org') }
    end

  end

end
