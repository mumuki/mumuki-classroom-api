require 'spec_helper'

describe Classroom::GuideProgress do
  let(:guide_progress) { Classroom::GuideProgress }

  before do
    Classroom::CourseStudent.insert!(
      student: {first_name: 'Jon', last_name: 'Doe', social_id: 'github|gh1234'},
      course: {slug: 'example/foo'})
  end

  after do
    Classroom::Database.clean!
  end

  describe '#update!' do
    context 'stores exercise data' do
      let(:submission) {
        {status: :passed,
         result: 'all right',
         submissions_count: 2,
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

      before do
        guide_progress.update!(submission)
      end

      let(:exercise) { guide_progress.exercise_by_student('example/foo', 'pdep-utn/foo', 'github|gh1234', 10)['exercise'] }

      it { expect(exercise['id']).to eq 10 }
      it { expect(exercise['name']).to eq 'First Steps 1' }
      it { expect(exercise['number']).to eq 7 }
    end
  end
end
