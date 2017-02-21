require 'spec_helper'

describe Exam do

  after do
    Classroom::Database.clean!
  end

  let(:except_fields) { {except: [:id, :created_at, :updated_at]} }

  describe 'get /courses/:course/exams' do
    let(:exam_json) { {slug: 'foo/bar', start_time: 'today', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', organization: 'example', course: 'example/foo'} }

    before { header 'Authorization', build_auth_header('*') }
    before { Exam.create!(exam_json) }
    before { get '/courses/foo/exams' }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to json_like({exams: [id: instance_of(String)]}, {only: :id}) }
    it { expect(last_response.body).to json_like({exams: [exam_json]}, except_fields) }

  end

  describe 'post /courses/:course/exams' do
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: []}.as_json }
    let(:exam_fetched) { Exam.find_by organization: 'example', course: 'example/foo' }

    before { expect(Mumukit::Nuntius::EventPublisher).to receive(:publish).with('UpsertExam', exam_json.merge('organization' => 'example', 'id' => kind_of(BSON::ObjectId))) }
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/foo/exams', exam_json.to_json }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to json_like({status: 'created'}, {except: :id}) }
    it { expect(Exam.where(organization: 'example', course: 'example/foo').count).to eq 1 }
    it { expect(exam_fetched.id).to be_truthy }
    it { expect(exam_fetched.id).to be_instance_of(BSON::ObjectId) }
    it { expect(exam_fetched.as_json).to json_like(exam_json.merge(organization: 'example', course: 'example/foo'), except_fields) }
  end

  describe 'post /api/courses/:course/exams' do
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: []}.as_json }
    let(:exam_fetched) { Exam.find_by organization: 'example', course: 'example/foo' }

    before { expect(Mumukit::Nuntius::EventPublisher).to receive(:publish).with('UpsertExam', exam_json.merge('organization' => 'example', 'id' => kind_of(BSON::ObjectId))) }
    before { header 'Authorization', build_mumuki_auth_header('*') }
    before { post '/api/courses/foo/exams', exam_json.to_json }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to json_like({status: 'created'}, except_fields) }
    it { expect(Exam.count).to eq 1 }
    it { expect(exam_fetched.id).to be_truthy }
    it { expect(exam_fetched.as_json).to json_like exam_json.merge(organization: 'example', course: 'example/foo'), except_fields }
  end

  describe 'get /courses/:course/exams/:exam_id' do
    let(:exam_id) { Exam.create!(exam_json.merge organization: 'example', course: 'example/foo').id }
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: []} }

    before { header 'Authorization', build_auth_header('*') }
    before { get "/courses/foo/exams/#{exam_id}", exam_json.to_json }

    it { expect(last_response.body).to json_like({id: exam_id}, {only: :id}) }
    it { expect(last_response.body).to json_like exam_json.merge(organization: 'example', course: 'example/foo'), except_fields }
  end

  describe 'put /courses/:course/exams/:exam' do
    let(:exam_id) { Exam.create!(exam_json.merge organization: 'example', course: 'example/foo').id }
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: ['auth0|234567', 'auth0|345678']}.as_json }
    let(:exam_json2) { exam_json.merge(uids: ['auth0|123456'], id: exam_id).as_json }
    let(:exam_fetched) { Exam.last }

    context 'when existing exam' do
      before { expect(Mumukit::Nuntius::EventPublisher).to receive(:publish).exactly(1).times }
      before { header 'Authorization', build_auth_header('*') }
      before { put "/courses/foo/exams/#{exam_id}", exam_json2.to_json }

      it { expect(last_response.body).to be_truthy }
      it { expect(last_response.body).to json_like({status: 'updated'}, except_fields) }
      it { expect(Exam.count).to eq 1 }
      it { expect(exam_fetched.id).to eq(exam_id) }
      it { expect(exam_fetched.as_json).to json_like exam_json2.merge(organization: 'example', course: 'example/foo'), except_fields }
    end

  end

  describe 'post /api/courses/:course/exams/:exam/students/:uid' do
    let(:exam_id) { Exam.create!(exam_json.merge organization: 'example', course: 'example/foo').id }
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: '150', language: 'haskell', name: 'foo', uids: ['auth0|234567', 'auth0|345678']}.stringify_keys }
    let(:exam_fetched) { Exam.last }

    context 'when existing exam' do
      before { expect(Mumukit::Nuntius::EventPublisher).to receive(:publish).exactly(1).times }
      before { header 'Authorization', build_mumuki_auth_header('*') }
      before { post "/api/courses/foo/exams/#{exam_id}/students/agus@mumuki.org" }

      it { expect(last_response.body).to be_truthy }
      it { expect(last_response.body).to json_like({status: 'updated'}, except_fields) }
      it { expect(Exam.count).to eq 1 }
      it { expect(exam_fetched.uids).to eq ['auth0|234567', 'auth0|345678', 'agus@mumuki.org'] }
    end

  end

end
