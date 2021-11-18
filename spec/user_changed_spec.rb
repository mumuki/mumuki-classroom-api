require 'spec_helper'

describe Mumuki::Classroom::Event::UserChanged do

  let(:uid) { 'john@doe.com' }

  let(:old_permissions) { {student: 'example.org/old-students', teacher: 'example.org/old-teachers'}.with_indifferent_access }
  let(:new_permissions) { {student: 'example.org/new-students', teacher: 'example.org/new-teachers'}.with_indifferent_access }

  let(:user) { {uid: uid, email: uid, last_name: 'Doe', first_name: 'John'}.with_indifferent_access }

  let(:event) { user.merge(old_permissions: old_permissions, new_permissions: new_permissions) }

  before { create :user, user.merge(permissions: old_permissions) }
  before { create :organization, name: 'example.org' }

  describe 'execute!' do

    context 'event with no permissions attribute' do
      let(:event) { user }
      before do
        expect(Mumuki::Classroom::Event::UserChanged).to_not receive(:student_added)
        expect(Mumuki::Classroom::Event::UserChanged).to_not receive(:teacher_added)
        expect(Mumuki::Classroom::Event::UserChanged).to_not receive(:student_removed)
        expect(Mumuki::Classroom::Event::UserChanged).to_not receive(:teacher_removed)
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
        expect(Mumuki::Classroom::Event::UserChanged).to receive(:teacher_removed)
      end
      before { Mumuki::Classroom::Event::UserChanged.execute! event }

      it { expect(Organization.pluck(:name)).to include 'example.org' }
      it { expect(Mumuki::Classroom::Event::UserChanged.changes['example.org'].map(&:description)).to eq %w(student_removed student_added teacher_removed teacher_added) }
      it { expect(Mumukit::Auth::Permissions::Diff.diff(old_permissions, new_permissions).as_json)
             .to json_like(changes: [
               {role: 'student', grant: 'example.org/old-students', type: 'removed'},
               {role: 'student', grant: 'example.org/new-students', type: 'added'},
               {role: 'teacher', grant: 'example.org/old-teachers', type: 'removed'},
               {role: 'teacher', grant: 'example.org/new-teachers', type: 'added'}]) }

    end

    context 'when courses exist' do
      before do
        create(:course, slug: 'example.org/old-students')
        create(:course, slug: 'example.org/new-students')
        create(:course, slug: 'example.org/old-teachers')
        create(:course, slug: 'example.org/new-teachers')
      end

      context 'update models' do
        before { Mumuki::Classroom::Student.create! user.merge(organization: 'example.org', course: 'example.org/old-students') }
        before { Mumuki::Classroom::Teacher.create! user.merge(organization: 'example.org', course: 'example.org/old-teachers') }

        before { Mumuki::Classroom::Event::UserChanged.execute! event }

        let(:event) do
          user
            .except(:first_name)
            .merge(social_id: 'foo', old_permissions: old_permissions, new_permissions: new_permissions)
        end

        let(:except_fields) { {except: [:created_at, :updated_at, :social_id, :image_url]} }

        let(:student_foo_fetched) { Mumuki::Classroom::Student.find_by(uid: uid, organization: 'example.org', course: 'example.org/old-students') }
        let(:student_bar_fetched) { Mumuki::Classroom::Student.find_by(uid: uid, organization: 'example.org', course: 'example.org/new-students') }
        let(:teacher_foo_fetched) { Mumuki::Classroom::Teacher.find_by(uid: uid, organization: 'example.org', course: 'example.org/old-teachers') }
        let(:teacher_bar_fetched) { Mumuki::Classroom::Teacher.find_by(uid: uid, organization: 'example.org', course: 'example.org/new-teachers') }

        it { expect(student_foo_fetched.detached).to eq true }
        it { expect(student_foo_fetched.uid).to eq uid }
        it { expect(student_foo_fetched.first_name).to eq 'John' }

        it { expect(student_bar_fetched.as_json).to json_like user.merge(organization: 'example.org', course: 'example.org/new-students'), except_fields }
        it { expect(student_bar_fetched.detached).to eq nil }

        it { expect(teacher_bar_fetched.as_json).to json_like user.merge(organization: 'example.org', course: 'example.org/new-teachers'), except_fields }
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
        let(:john_submission) do
          submission.merge({
            organization: 'example.org',
            submitter: user,
            exercise: exercise,
            guide: guide
          })
        end
        let(:mary_submission) do
          submission.merge({
            organization: 'example.org',
            submitter: mary_h,
            exercise: exercise,
            guide: guide
          })
        end
        let(:mary_uid) { 'mary@doe.com' }
        let(:mary_h) { {uid: mary_uid, email: mary_uid, last_name: 'Doe', first_name: 'Mary'}.with_indifferent_access }
        let(:mary_event) { mary_h.merge(last_name: 'Marie', permissions: old_permissions) }
        before { create :user, uid: mary_uid, permissions: old_permissions }

        before { Mumuki::Classroom::Student.create! user.merge(organization: 'example.org', course: 'example.org/old-students') }
        before { Mumuki::Classroom::Student.create! mary_h.merge(organization: 'example.org', course: 'example.org/old-students') }
        before { Mumuki::Classroom::Submission.process!(john_submission) }
        before { Mumuki::Classroom::Submission.process!(mary_submission) }
        before { Mumuki::Classroom::Event::UserChanged.execute! mary_event }

        it { expect(Mumuki::Classroom::Assignment.where('student.uid': uid).count).to eq 1 }
        it { expect(Mumuki::Classroom::Assignment.where('student.uid': mary_uid).count).to eq 1 }
        it { expect(Mumuki::Classroom::GuideProgress.where('student.uid': uid).count).to eq 1 }
        it { expect(Mumuki::Classroom::GuideProgress.where('student.uid': mary_uid).count).to eq 1 }

      end
    end

  end
end
