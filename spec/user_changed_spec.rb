require 'spec_helper'

describe Mumuki::Classroom::Event::UserChanged do

  let(:uid) { 'agus@mumuki.org' }
  let(:uid2) { 'fedescarpa@mumuki.org' }
  let(:event) { user.merge(permissions: new_permissions) }
  let(:old_permissions) { {student: 'example.org/foo'}.with_indifferent_access }
  let(:new_permissions) { {student: 'example.org/bar', teacher: 'example.org/foo'}.with_indifferent_access }
  let(:user) { {uid: uid, email: uid, last_name: 'Pina', first_name: 'Agustín'}.with_indifferent_access }
  let(:user2) { {uid: uid2, email: uid2, last_name: 'Scarpa', first_name: 'Federico'}.with_indifferent_access }
  let(:except_fields) { {except: [:created_at, :updated_at]} }

  before { User.create! uid: uid, permissions: old_permissions }
  before { create :organization, name: 'example.org' }

  describe 'execute!' do

    context 'event with no permissions attribute' do
      let(:event) { user }
      before do
        expect(Mumuki::Classroom::Event::UserChanged).to_not receive(:student_added)
        expect(Mumuki::Classroom::Event::UserChanged).to_not receive(:teacher_added)
        expect(Mumuki::Classroom::Event::UserChanged).to_not receive(:student_removed)
      end
      before { Mumuki::Classroom::Event::UserChanged.execute! event }

      it { expect(Organization.pluck(:name)).to include 'example.org' }
      it { expect(Mumuki::Classroom::Event::UserChanged.changes).to be_empty }
    end


    context 'save new permissions' do
      before do
        expect(Mumuki::Classroom::Event::UserChanged).to receive(:student_added)
        expect(Mumuki::Classroom::Event::UserChanged).to receive(:teacher_added)
        expect(Mumuki::Classroom::Event::UserChanged).to receive(:student_removed)
      end
      before { Mumuki::Classroom::Event::UserChanged.execute! event }

      it { expect(Organization.pluck(:name)).to include 'example.org' }
      it { expect(Mumuki::Classroom::Event::UserChanged.changes['example.org'].map(&:description)).to eq %w(student_removed student_added teacher_added) }
      it { expect(Mumukit::Auth::Permissions::Diff.diff(old_permissions, new_permissions).as_json)
             .to json_like(changes: [
               {role: 'student', grant: 'example.org/foo', type: 'removed'},
               {role: 'student', grant: 'example.org/bar', type: 'added'},
               {role: 'teacher', grant: 'example.org/foo', type: 'added'}]) }

    end

    context 'update models' do

      let!(:course) { create(:course, slug: 'example.org/foo') }
      let!(:course) { create(:course, slug: 'example.org/bar') }
      before { Mumuki::Classroom::Student.create! user.merge(organization: 'example.org', course: 'example.org/foo') }
      before { Mumuki::Classroom::Event::UserChanged.execute! event }

      let(:user2) { user.merge(social_id: 'foo').except(:first_name) }
      let(:event) { user2.merge(permissions: new_permissions) }

      let(:student_foo_fetched) { Mumuki::Classroom::Student.find_by(uid: uid, organization: 'example.org', course: 'example.org/foo') }
      let(:student_bar_fetched) { Mumuki::Classroom::Student.find_by(uid: uid, organization: 'example.org', course: 'example.org/bar') }
      let(:teacher_foo_fetched) { Mumuki::Classroom::Teacher.find_by(uid: uid, organization: 'example.org', course: 'example.org/foo') }

      it { expect(student_foo_fetched.detached).to eq true }
      it { expect(student_foo_fetched.uid).to eq uid }
      it { expect(student_foo_fetched.first_name).to eq 'Agustín' }

      it { expect(student_bar_fetched.as_json).to json_like user2.merge(organization: 'example.org', course: 'example.org/bar'), except_fields }
      it { expect(student_bar_fetched.detached).to eq nil }

      it { expect(teacher_foo_fetched.as_json).to json_like user2.merge(organization: 'example.org', course: 'example.org/foo'), except_fields }
    end

    context 'when there are assignments for several users, user changed event only updates the assignment for that student' do
      let(:chapter) { {
        id: 'guide_chapter_id',
        name: 'guide_chapter_name'
      } }
      let(:parent) { {
        type: 'Lesson',
        name: 'A lesson name',
        position: '1',
        chapter: chapter
      } }
      let(:guide) { {
        slug: 'guide_slug',
        name: 'guide_name',
        parent: parent,
        language: {
          name: 'guide_language_name',
          devicon: 'guide_language_devicon'
        }
      } }
      let(:exercise) { {
        eid: 1,
        name: 'exercise_name',
        number: 1
      } }
      let(:submission) { {
        sid: '1',
        status: 'passed',
        result: 'result',
        content: 'find f = head.filter f',
        feedback: 'feedback',
        created_at: '2016-01-01 00:00:00',
        test_results: ['test_results'],
        submissions_count: 1,
        expectation_results: []
      } }
      let(:agus_submission) { submission.merge({
                                                 organization: 'example.org',
                                                 submitter: user,
                                                 exercise: exercise,
                                                 guide: guide
                                               }) }
      let(:fede_submission) { submission.merge({
                                                 organization: 'example.org',
                                                 submitter: user2,
                                                 exercise: exercise,
                                                 guide: guide
                                               }) }
      let(:event2) { user2.merge(last_name: 'Otro', permissions: old_permissions) }
      before { User.create! uid: uid2, permissions: old_permissions }
      let!(:course) { create(:course, slug: 'example.org/foo') }
      let!(:course) { create(:course, slug: 'example.org/bar') }
      before { Mumuki::Classroom::Student.create! user.merge(organization: 'example.org', course: 'example.org/foo') }
      before { Mumuki::Classroom::Student.create! user2.merge(organization: 'example.org', course: 'example.org/foo') }
      before { Mumuki::Classroom::Submission.process!(agus_submission) }
      before { Mumuki::Classroom::Submission.process!(fede_submission) }
      before { Mumuki::Classroom::Event::UserChanged.execute! event2 }

      it { expect(Mumuki::Classroom::Assignment.where('student.uid': uid).count).to eq 1 }
      it { expect(Mumuki::Classroom::Assignment.where('student.uid': uid2).count).to eq 1 }
      it { expect(Mumuki::Classroom::GuideProgress.where('student.uid': uid).count).to eq 1 }
      it { expect(Mumuki::Classroom::GuideProgress.where('student.uid': uid2).count).to eq 1 }

    end

  end
end
