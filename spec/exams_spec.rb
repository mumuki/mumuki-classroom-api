require 'spec_helper'

describe Exam, workspaces: [:organization, :courses] do

  let(:organization) { Organization.locate! 'example.org' }
  let(:course) { Course.locate! 'example.org/foo' }
  let(:language) { Language.for_name 'haskell' }
  let(:guide) { create :guide, slug: 'foo/bar', name: 'foo', language: language }
  let(:jane) { create :user, uid: 'jane.doe@testing.com' }
  let(:john) { create :user, uid: 'john.doe@testing.com' }

  let(:start_time) { 1.month.ago.beginning_of_day }
  let(:end_time) { 1.month.since.beginning_of_day }

  let(:exam_json) { {
    organization: organization.name,
    course: course.slug,
    slug: guide.slug,
    language: guide.language.name,
    name: guide.name,
    start_time: start_time,
    end_time: end_time,
    duration: 150,
    max_problem_submissions: 5,
    max_choice_submissions: 1,
    results_hidden_for_choices: false,
    passing_criterion_type: 'none'
  } }

  let(:response) { struct JSON.parse(last_response.body) }

  before { header 'Authorization', build_auth_header('*') }

  describe 'get /courses/:course/exams' do

    before { Exam.import_from_resource_h! exam_json }
    before { get '/courses/foo/exams' }

    let(:exam) { struct response.exams[0] }

    it { expect(last_response.body).to be_truthy }
    it { expect(response.exams.size).to eq 1 }
    it { expect(exam.eid).to be_instance_of String }
    it { expect(exam.organization).to eq organization.name }
    it { expect(exam.course).to eq course.slug }
    it { expect(exam.slug).to eq guide.slug }
    it { expect(exam.start_time.to_datetime).to eq start_time }
    it { expect(exam.end_time.to_datetime).to eq end_time }
    it { expect(exam.duration).to eq 150 }
    it { expect(exam.max_problem_submissions).to eq 5 }
    it { expect(exam.max_choice_submissions).to eq 1 }
    it { expect(exam.results_hidden_for_choices).to eq false }

  end

  describe 'post /courses/:course/exams' do

    let(:exams_fetched) { Exam.where organization: organization, course: course }
    let(:exam_fetched) { exams_fetched.first }

    ['/api', ''].each do |prefix|
      context prefix do
        before { post "#{prefix}/courses/foo/exams", exam_json.to_json }
        it { expect(last_response.body).to be_truthy }
        it { expect(response.status).to eq 'created' }
        it { expect(response.eid).to be_instance_of(String) }
        it { expect(exams_fetched.count).to eq 1 }
        it { expect(exam_fetched.classroom_id).to be_instance_of(String) }
        it { expect(exam_fetched.organization).to eq organization }
        it { expect(exam_fetched.course).to eq course }
        it { expect(exam_fetched.guide).to eq guide }
        it { expect(exam_fetched.start_time).to eq start_time }
        it { expect(exam_fetched.end_time).to eq end_time }
        it { expect(exam_fetched.duration).to eq 150 }
        it { expect(exam_fetched.max_problem_submissions).to eq 5 }
        it { expect(exam_fetched.max_choice_submissions).to eq 1 }
        it { expect(exam_fetched.results_hidden_for_choices).to eq false }
      end
    end
  end

  describe 'get /courses/:course/exams/:exam_id' do
    let(:classroom_id) { Exam.import_from_resource_h!(exam_json).classroom_id }

    before { get "/courses/foo/exams/#{classroom_id}", exam_json.to_json }

    it { expect(response.eid).to eq classroom_id }
    it { expect(response.organization).to eq organization.name }
    it { expect(response.course).to eq course.slug }
    it { expect(response.slug).to eq guide.slug }
    it { expect(response.name).to eq guide.name }
    it { expect(response.language).to eq language.name }
    it { expect(response.start_time.to_datetime).to eq start_time.to_datetime }
    it { expect(response.end_time.to_datetime).to eq end_time.to_datetime }
    it { expect(response.duration).to eq 150 }
    it { expect(response.max_problem_submissions).to eq 5 }
    it { expect(response.max_choice_submissions).to eq 1 }
    it { expect(response.results_hidden_for_choices).to eq false }
  end

  describe 'put /courses/:course/exams/:exam not update users list' do
    let(:classroom_id) { (Exam.import_from_resource_h! exam_json).classroom_id }
    let(:exam_json2) { exam_json.merge(eid: classroom_id, max_choice_submissions: 3, uids: [jane.uid, john.uid]) }
    let(:exam_fetched) { Exam.last }

    context 'when existing exam' do
      before { put "/courses/foo/exams/#{classroom_id}", exam_json2.to_json }

      it { expect(last_response.body).to be_truthy }
      it { expect(response.status).to eq 'updated' }
      it { expect(Exam.count).to eq 1 }
      it { expect(exam_fetched.classroom_id).to eq classroom_id }
      it { expect(exam_fetched.organization).to eq organization }
      it { expect(exam_fetched.course).to eq course }
      it { expect(exam_fetched.guide).to eq guide }
      it { expect(exam_fetched.start_time).to eq start_time }
      it { expect(exam_fetched.end_time).to eq end_time }
      it { expect(exam_fetched.duration).to eq 150 }
      it { expect(exam_fetched.max_problem_submissions).to eq 5 }
      it { expect(exam_fetched.max_choice_submissions).to eq 3 }
      it { expect(exam_fetched.results_hidden_for_choices).to eq false }
      it { expect(exam_fetched.users.size).to eq 0 }
    end

  end

  describe 'post /courses/:course/exams/:exam/students/:uid' do
    let(:classroom_id) { (Exam.import_from_resource_h! exam_json).classroom_id }

    ['/api', ''].each do |prefix|
      context prefix do
        before { Exam.upsert_students! eid: classroom_id, added: [jane.uid] }
        before { post "/api/courses/foo/exams/#{classroom_id}/students/#{john.uid}" }

        it { expect(last_response.body).to be_truthy }
        it { expect(response.status).to eq 'updated' }
        it { expect(Exam.count).to eq 1 }
        it { expect(Exam.last.users).to eq [jane, john] }
      end
    end
  end

  describe 'delete /courses/:course/exams/:exam/students/:uid' do

    let(:classroom_id) { (Exam.import_from_resource_h! exam_json).classroom_id }

    ['/api', ''].each do |prefix|
      context prefix do
        before { Exam.upsert_students! eid: classroom_id, added: [jane.uid, john.uid] }
        before { delete "/api/courses/foo/exams/#{classroom_id}/students/#{john.uid}" }

        it { expect(last_response.body).to be_truthy }
        it { expect(response.status).to eq 'updated' }
        it { expect(Exam.count).to eq 1 }
        it { expect(Exam.last.users).to eq [jane] }
      end
    end
  end

  describe 'exam validations' do
    context 'max submissions' do

      let(:valid_exam_json) { exam_json.merge(max_problem_submissions: 1, max_choice_submissions: 1) }
      let(:invalid_exam_json1) { exam_json.merge(max_problem_submissions: 1, max_choice_submissions: -2) }
      let(:invalid_exam_json2) { exam_json.merge(max_problem_submissions: -2, max_choice_submissions: 1) }

      it { expect { Exam.import_from_resource_h! valid_exam_json }.not_to raise_error }
      it { expect { Exam.import_from_resource_h! invalid_exam_json1 }.to raise_error(ActiveRecord::RecordInvalid) }
      it { expect { Exam.import_from_resource_h! invalid_exam_json2 }.to raise_error(ActiveRecord::RecordInvalid) }
    end

    context 'passing criterion' do

      let(:valid_criterion_none) { exam_json.merge(passing_criterion_type: 'none') }
      let(:valid_criterion_passed_exercises) { exam_json.merge(passing_criterion_type: 'passed_exercises', passing_criterion_value: 5) }
      let(:valid_criterion_percentage) { exam_json.merge(passing_criterion_type: 'percentage', passing_criterion_value: 10) }

      let(:invalid_criterion_type) { exam_json.merge(passing_criterion_type: 'some_invalid_type') }
      let(:invalid_criterion_value) { exam_json.merge(passing_criterion_type: 'percentage', passing_criterion_value: 105) }

      it { expect { Exam.import_from_resource_h! valid_criterion_none }.not_to raise_error }
      it { expect { Exam.import_from_resource_h! valid_criterion_passed_exercises }.not_to raise_error }
      it { expect { Exam.import_from_resource_h! valid_criterion_percentage }.not_to raise_error }
      it { expect { Exam.import_from_resource_h! invalid_criterion_type }.to raise_error(ArgumentError) }
      it { expect { Exam.import_from_resource_h! invalid_criterion_value }.to raise_error('Invalid criterion value 105 for percentage') }
    end
  end

end
