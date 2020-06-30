require 'spec_helper'

describe Exam do

  let(:except_fields) { {except: [:eid, :created_at, :updated_at]} }

  describe 'get /courses/:course/exams' do
    let(:exam_json) { {slug: 'foo/bar', start_time: 'today', end_time: 'tomorrow', duration: 150, language: 'haskell', name: 'foo', organization: 'example.org', course: 'example.org/foo', passing_criterion: {type: 'none'}, results_hidden_for_choices: false} }

    before { header 'Authorization', build_auth_header('*') }
    before { Exam.create!(exam_json) }
    before { get '/courses/foo/exams' }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to json_like({exams: [eid: instance_of(String)]}, {only: :eid}) }
    it { expect(last_response.body).to json_like({exams: [exam_json]}, except_fields) }

  end

  describe 'post /courses/:course/exams' do
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: 150, language: 'haskell', name: 'foo', uids: [], passing_criterion: {type: 'none'}, results_hidden_for_choices: true}.as_json }
    let(:exam_fetched) { Exam.find_by organization: 'example.org', course: 'example.org/foo' }

    before { expect(Mumukit::Nuntius).to receive(:notify_event!).with('UpsertExam', exam_json.merge('organization' => 'example.org', 'course' => 'example.org/foo', 'eid' => kind_of(String))) }
    before { header 'Authorization', build_auth_header('*') }
    before { post '/courses/foo/exams', exam_json.to_json }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to json_like({status: 'created'}, {except: :eid}) }
    it { expect(Exam.where(organization: 'example.org', course: 'example.org/foo').count).to eq 1 }
    it { expect(exam_fetched.eid).to be_truthy }
    it { expect(exam_fetched.eid).to be_instance_of(String) }
    it { expect(exam_fetched.as_json).to json_like(exam_json.merge(organization: 'example.org', course: 'example.org/foo'), except_fields) }
  end

  describe 'post /api/courses/:course/exams' do
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: 150, language: 'haskell', name: 'foo', uids: [], passing_criterion: {type: 'none'}, results_hidden_for_choices: false}.as_json }
    let(:exam_fetched) { Exam.find_by organization: 'example.org', course: 'example.org/foo' }

    before { expect(Mumukit::Nuntius).to receive(:notify_event!).with('UpsertExam', exam_json.merge('organization' => 'example.org', 'course' => 'example.org/foo', 'eid' => kind_of(String))) }
    before { header 'Authorization', build_mumuki_auth_header('*') }
    before { post '/api/courses/foo/exams', exam_json.to_json }

    it { expect(last_response.body).to be_truthy }
    it { expect(last_response.body).to json_like({status: 'created'}, except_fields) }
    it { expect(Exam.count).to eq 1 }
    it { expect(exam_fetched.eid).to be_truthy }
    it { expect(exam_fetched.as_json).to json_like exam_json.merge(organization: 'example.org', course: 'example.org/foo'), except_fields }
  end

  describe 'get /courses/:course/exams/:exam_id' do
    let(:exam_id) { Exam.create!(exam_json.merge organization: 'example.org', course: 'example.org/foo').eid }
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: 150, language: 'haskell', name: 'foo', uids: [], passing_criterion: {type: 'none'}, results_hidden_for_choices: true} }

    before { header 'Authorization', build_auth_header('*') }
    before { get "/courses/foo/exams/#{exam_id}", exam_json.to_json }

    it { expect(last_response.body).to json_like({eid: exam_id}, {only: :eid}) }
    it { expect(last_response.body).to json_like exam_json.merge(organization: 'example.org', course: 'example.org/foo'), except_fields }
  end

  describe 'put /courses/:course/exams/:exam' do
    let(:exam_id) { Exam.create!(exam_json.merge organization: 'example.org', course: 'example.org/foo').eid }
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: 150, language: 'haskell', name: 'foo', uids: ['auth0|234567', 'auth0|345678'], passing_criterion: {type: 'none'}, results_hidden_for_choices: true}.as_json }
    let(:exam_json2) { exam_json.merge(uids: ['auth0|123456'], eid: exam_id).as_json }
    let(:exam_fetched) { Exam.last }

    context 'when existing exam' do
      before { expect(Mumukit::Nuntius).to receive(:notify_event!).exactly(1).times }
      before { header 'Authorization', build_auth_header('*') }
      before { put "/courses/foo/exams/#{exam_id}", exam_json2.to_json }

      it { expect(last_response.body).to be_truthy }
      it { expect(last_response.body).to json_like({status: 'updated'}, except_fields) }
      it { expect(Exam.count).to eq 1 }
      it { expect(exam_fetched.eid).to eq(exam_id) }
      it { expect(exam_fetched.as_json).to json_like exam_json2.merge(organization: 'example.org', course: 'example.org/foo'), except_fields }
    end

  end

  describe 'post /api/courses/:course/exams/:exam/students/:uid' do
    let(:exam_id) { Exam.create!(exam_json.merge organization: 'example.org', course: 'example.org/foo').eid }
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: 150, language: 'haskell', name: 'foo', uids: ['auth0|234567', 'auth0|345678'], passing_criterion: {type: 'none'}}.stringify_keys }
    let(:exam_fetched) { Exam.last }

    context 'when existing exam' do
      before { expect(Mumukit::Nuntius).to receive(:notify_event!).exactly(1).times }
      before { header 'Authorization', build_mumuki_auth_header('*') }
      before { post "/api/courses/foo/exams/#{exam_id}/students/agus@mumuki.org" }

      it { expect(last_response.body).to be_truthy }
      it { expect(last_response.body).to json_like({status: 'updated'}, except_fields) }
      it { expect(Exam.count).to eq 1 }
      it { expect(exam_fetched.uids).to eq ['auth0|234567', 'auth0|345678', 'agus@mumuki.org'] }
    end

  end

  describe 'post /api/courses/:course/massive/exams/:exam/students' do
    let(:exam_id) { Exam.create!(exam_json.merge organization: 'example.org', course: 'example.org/foo').eid }
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: 150, language: 'haskell', name: 'foo', uids: ['auth0|234567', 'auth0|345678'], passing_criterion: {type: 'none'}}.stringify_keys }
    let(:exam_fetched) { Exam.last }
    let(:exam_uids) { {uids: [1..100].map { |it| "user_uid_#{it}"} } }
    let(:uids) { exam_uids[:uids] }

    context 'when existing exam' do
      before { expect(Mumukit::Nuntius).to receive(:notify_event!).exactly(1).times }
      before { header 'Authorization', build_mumuki_auth_header('*') }
      before { post "/api/courses/foo/massive/exams/#{exam_id}/students", exam_uids.to_json }

      it { expect(last_response.body).to be_truthy }
      it { expect(last_response.body).to json_like({status: 'updated', processed_count: uids.size, processed: uids}, except_fields) }
      it { expect(Exam.count).to eq 1 }
      it { expect(exam_fetched.uids).to eq ['auth0|234567', 'auth0|345678'].concat(uids) }
    end

  end

  describe 'delete /api/courses/:course/exams/:exam/students/:uid' do
    let(:exam_id) { Exam.create!(exam_json.merge organization: 'example.org', course: 'example.org/foo').eid }
    let(:exam_json) { {slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: 150, language: 'haskell', name: 'foo', uids: ['auth0|234567', 'agus@mumuki.org', 'auth0|345678'], passing_criterion: {type: 'none'}}.stringify_keys }
    let(:exam_fetched) { Exam.last }

    context 'when existing exam' do
      before { expect(Mumukit::Nuntius).to receive(:notify_event!).exactly(1).times }
      before { header 'Authorization', build_mumuki_auth_header('*') }
      before { delete "/api/courses/foo/exams/#{exam_id}/students/agus@mumuki.org" }

      it { expect(last_response.body).to be_truthy }
      it { expect(last_response.body).to json_like({status: 'updated'}, except_fields) }
      it { expect(Exam.count).to eq 1 }
      it { expect(exam_fetched.uids).to eq ['auth0|234567', 'auth0|345678'] }
    end

  end

  describe 'exam validations' do
    context 'max submissions' do
      let(:exam_json) { {organization: 'example.org', course: 'example.org/foo', slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: 150, language: 'haskell', name: 'foo', uids: ['auth0|234567', 'auth0|345678'], passing_criterion: {type: 'none'}} }
      let(:valid_exam_json) { exam_json.merge(results_hidden_for_choices: true, max_problem_submissions: 10, max_choice_submissions: 2) }
      let(:invalid_exam_json) { exam_json.merge(max_problem_submissions: 0, max_choice_submissions: -2) }

      it { expect { Exam.create! valid_exam_json }.not_to raise_error }
      it { expect { Exam.create! invalid_exam_json }.to raise_error(Mongoid::Errors::Validations) }
    end

    context 'passing criterion' do
      let(:exam_json) { {organization: 'example.org', course: 'example.org/foo', slug: 'foo/bar', start_time: 'tomorrow', end_time: 'tomorrow', duration: 150, language: 'haskell', name: 'foo', uids: ['auth0|234567', 'auth0|345678']} }
      let(:valid_criterion_none) { exam_json.merge(passing_criterion: {type: 'none'}) }
      let(:valid_criterion_passed_exercises) { exam_json.merge(passing_criterion: {type: 'passed_exercises', value: 5}) }
      let(:valid_criterion_percentage) { exam_json.merge(passing_criterion: {type: 'percentage', value: 10}) }

      let(:invalid_criterion_type) { exam_json.merge(passing_criterion: {type: 'some_invalid_type'}) }
      let(:invalid_criterion_value) { exam_json.merge(passing_criterion: {type: 'percentage', value: 105}) }

      it { expect { Exam.create! valid_criterion_none }.not_to raise_error }
      it { expect { Exam.create! valid_criterion_passed_exercises }.not_to raise_error }
      it { expect { Exam.create! valid_criterion_percentage }.not_to raise_error }
      it { expect { Exam.create! invalid_criterion_type }.to raise_error('Invalid criterion type some_invalid_type') }
      it { expect { Exam.create! invalid_criterion_value }.to raise_error('Invalid criterion value 105 for percentage') }
    end
  end
end
