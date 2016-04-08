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

    context 'when student starts a new guide' do
      let(:guide_progress) { Classroom::GuideProgress.find('guide.slug' => 'pdep-utn/foo', 'course.slug' => 'example/foo').first }

      let(:expected_guide) { {'slug' => 'pdep-utn/foo', 'name' => 'Foo', 'language' => {'name' => 'haskell'}} }
      it { expect(guide_progress['guide']).to eq expected_guide }

      let(:expected_exercise) { {'id' => 10, 'name' => 'First Steps 1', 'number' => 7} }
      it { expect(guide_progress['exercises'].first).to include expected_exercise }

      let(:expected_submissions) { [{'id' => 'abcd1234', 'status' => 'passed', 'result' => 'all right', 'expectation_results' => nil, 'test_results' => nil, 'feedback' => nil, 'submissions_count' => nil, 'created_at' => nil, 'content' => 'x = 2'}] }
      it { expect(guide_progress['exercises'].first['submissions']).to eq expected_submissions }
    end
  end
end
