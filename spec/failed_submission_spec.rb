require 'spec_helper'

describe Classroom::FailedSubmission do

  after do
    organization(:central) {Classroom::Database.clean!}
    organization(:example) {Classroom::Database.clean!}
  end

  def organization(org)
    Classroom::Database.organization = org
    yield
  end

  let(:submitter) {{social_id: 'github|123456'}}
  let(:chapter) {{id: 'guide_chapter_id', name: 'guide_chapter_name'} }
  let(:parent) {{type: 'Lesson', name: 'A lesson name', position: '1', chapter: chapter} }
  let(:guide) {{slug: 'guide_slug', name: 'guide_name', parent: parent, language: {name: 'guide_language_name', devicon: 'guide_language_devicon'}} }
  let(:exercise) {{id: 1, name: 'exercise_name', number: 1} }
  let(:submission) {{id: 1, status: 'passed', result: 'result', content: 'find f = head.filter f', feedback: 'feedback', created_at: '2016-01-01 00:00:00', test_results: 'test_results', submissions_count: 1, expectation_results: 'expectation_results'} }

  let(:atheneum_submission) { submission.merge({
    submitter: submitter,
    exercise: exercise,
    guide: guide
  })}

  describe 'when resubmission is consumed' do

    let(:central_count) { organization(:central) { Classroom::Collection::FailedSubmissions.count }}
    let(:example_count) { organization(:example) { Classroom::Collection::FailedSubmissions.count }}

    before do
      organization('central') do
        Classroom::Collection::FailedSubmissions.insert! atheneum_submission.wrap_json
        Classroom::Collection::FailedSubmissions.insert! atheneum_submission.merge(submitter: {social_id: 'github|234567'}).wrap_json
      end
      organization('example') do
        Classroom::Collection::FailedSubmissions.insert! atheneum_submission.wrap_json
        Classroom::Collection::FailedSubmissions.insert! atheneum_submission.wrap_json
      end
    end

    context 'and submission.process! works' do
      before { expect(Classroom::Submission).to receive(:process!).exactly(3).times }
      before { expect(Classroom::Collection::FailedSubmissions).to_not receive(:insert!) }
      before { Classroom::FailedSubmission.reprocess!(submitter[:social_id], :example) }

      it { expect(central_count).to eq(1) }
      it { expect(example_count).to eq(0) }
    end

    context 'and submission.process! does not work' do
      before { allow(Classroom::Submission).to receive(:process!).and_raise(StandardError) }
      before { Classroom::FailedSubmission.reprocess!('github|234567', :example) }

      it { expect(central_count).to eq(2) }
      it { expect(example_count).to eq(2) }
    end

    context 'and submission.process! does not work one time' do
      before { expect(Classroom::Submission).to receive(:process!).once.and_raise(StandardError) }
      before { expect(Classroom::Submission).to receive(:process!).twice }
      before { Classroom::FailedSubmission.reprocess!('github|123456', :example) }

      it { expect(central_count).to eq(1) }
      it { expect(example_count).to eq(1) }
    end

  end

end