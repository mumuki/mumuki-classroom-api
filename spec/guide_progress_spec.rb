require 'spec_helper'

describe Classroom::GuideProgress do
  before do
    Classroom::CourseStudent.insert!(
      student: {first_name: 'Jon', last_name: 'Doe', social_id: 'github|gh1234'},
      course: {slug: 'example/foo'})
  end

  after do
    Classroom::Database.clean!
  end

  let(:submission) {
    {status: :passed,
     result: 'all right',
     exercise: {
       id: 10,
       name: 'First Steps 1',
       number: 7},
     guide: { slug: 'pdep-utn/foo',
              name: 'Foo',
              language: {name: 'haskell'}},
     submitter: {
       social_id: 'github|gh1234'},
     id: 'abcd1234',
     content: 'x = 2'}.as_json }

  describe '#update!' do
    before do
      Classroom::GuideProgress.update!(submission)
    end

    let(:guide_progress) { Classroom::GuideProgress.find('guide.slug' => 'pdep-utn/foo', 'course.slug' => 'example/foo') }
    let(:first_guide_progress) { guide_progress.first }

    context 'when student starts a new guide' do
      let(:expected_guide) { {'slug' => 'pdep-utn/foo', 'name' => 'Foo', 'language' => {'name' => 'haskell'}} }
      it { expect(first_guide_progress['guide']).to eq expected_guide }

      let(:expected_exercise) { {'id' => 10, 'name' => 'First Steps 1', 'number' => 7} }
      it { expect(first_guide_progress['exercises'].first).to include expected_exercise }

      let(:expected_submissions) { [{'id' => 'abcd1234', 'status' => 'passed', 'result' => 'all right', 'expectation_results' => nil, 'test_results' => nil, 'feedback' => nil, 'submissions_count' => nil, 'created_at' => nil, 'content' => 'x = 2'}] }
      it { expect(first_guide_progress['exercises'].first['submissions']).to eq expected_submissions }
    end

    context 'when new exercise is submitted for existing guide' do
      before do
        Classroom::GuideProgress.update! submission.merge({'id' => 'abc1235', 'exercise' => {'id' => 25, 'name' => 'Second Steps', 'number' => 8}})
      end

      it { expect(guide_progress.count).to eq 1 }
      it { expect(first_guide_progress['exercises'].size).to eq 2 }
      it { expect(first_guide_progress['exercises'].second['submissions'].size).to eq 1 }
    end

    context 'when new submission is submitted for existing exercise' do
      before do
        Classroom::GuideProgress.update! submission.merge({'id' => 'abc1235'})
      end

      it { expect(guide_progress.count).to eq 1 }
      it { expect(first_guide_progress['exercises'].size).to eq 1 }
      it { expect(first_guide_progress['exercises'].first['submissions'].size).to eq 2 }
    end

    context 'when exercise has changed, a new submission updates it' do
      let(:submission) {
        {status: :passed,
         result: 'all right',
         exercise: {
           id: 10,
           name: 'First Steps 1'},
         guide: { slug: 'pdep-utn/foo',
                  name: 'Foo',
                  language: {name: 'haskell'}},
         submitter: {
           social_id: 'github|gh1234'},
         id: 'abcd1234',
         content: 'x = 2'}.as_json }

      before do
        Classroom::GuideProgress.update! submission.merge({'exercise' => {'id' => 10, 'name' => 'New name', 'number' => 3}})
      end

      it { expect(guide_progress.count).to eq 1 }
      it { expect(first_guide_progress['exercises'].size).to eq 1 }
      it { expect(first_guide_progress['exercises'].first['submissions'].size).to eq 2 }
      it { expect(first_guide_progress['exercises'].first).to include({'id' => 10, 'name' => 'New name', 'number' => 3}) }
    end
  end
end
