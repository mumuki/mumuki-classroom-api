require 'spec_helper'

describe Mumuki::Classroom::FailedSubmission do

  let(:submitter) { {uid: 'github|123456'} }
  let(:chapter) { {id: 'guide_chapter_id', name: 'guide_chapter_name'} }
  let(:parent) { {type: 'Lesson', name: 'A lesson name', position: '1', chapter: chapter} }
  let(:guide) { {slug: 'guide_slug', name: 'guide_name', parent: parent, language: {name: 'guide_language_name', devicon: 'guide_language_devicon'}} }
  let(:exercise) { {sid: 1, name: 'exercise_name', number: 1} }
  let(:submission) { {sid: 1, status: 'passed', result: 'result', content: 'find f = head.filter f', feedback: 'feedback', created_at: '2016-01-01 00:00:00', test_results: 'test_results', submissions_count: 1, expectation_results: 'expectation_results'} }

  let(:atheneum_submission) { submission.merge submitter: submitter,
                                               exercise: exercise,
                                               guide: guide }

  describe 'when resubmission is consumed' do

    let(:central_count) { Mumuki::Classroom::FailedSubmission.for('central').count }
    let(:example_count) { Mumuki::Classroom::FailedSubmission.for('example').count }

    before do
      Mumuki::Classroom::FailedSubmission.create! atheneum_submission.merge(organization: 'central')
      Mumuki::Classroom::FailedSubmission.create! atheneum_submission.merge(organization: 'central', submitter: {uid: 'github|234567'})
      Mumuki::Classroom::FailedSubmission.create! atheneum_submission.merge(organization: 'example')
      Mumuki::Classroom::FailedSubmission.create! atheneum_submission.merge(organization: 'example')
    end

    context 'and submission.process! works' do
      before { expect(Mumuki::Classroom::Submission).to receive(:process!).exactly(3).times }
      before { expect(Mumuki::Classroom::FailedSubmission).to_not receive(:create!) }
      before { Mumuki::Classroom::FailedSubmission.reprocess!(submitter[:uid], :example) }

      it { expect(central_count).to eq(2) }
      it { expect(example_count).to eq(0) }
    end

    context 'and submission.process! does not work' do
      before { allow(Mumuki::Classroom::Submission).to receive(:process!).and_raise(StandardError) }
      before { Mumuki::Classroom::FailedSubmission.reprocess!('github|234567', :example) }

      it { expect(central_count).to eq(2) }
      it { expect(example_count).to eq(2) }
    end

    context 'and submission.process! does not work one time' do
      before { expect(Mumuki::Classroom::Submission).to receive(:process!).once.and_raise(StandardError) }
      before { expect(Mumuki::Classroom::Submission).to receive(:process!).twice }
      before { Mumuki::Classroom::FailedSubmission.reprocess!('github|123456', :example) }

      it { expect(central_count).to eq(1) }
      it { expect(example_count).to eq(1) }
    end

  end

end
