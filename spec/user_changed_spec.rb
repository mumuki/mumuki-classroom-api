require 'spec_helper'

describe Classroom::Event::UserChanged do

  let(:uid) { 'agus@mumuki.org' }
  let(:event) { {user: user.merge(permissions: new_permissions)} }
  let(:old_permissions) { {student: 'example/foo'}.with_indifferent_access }
  let(:new_permissions) { {student: 'example/bar', teacher: 'example/foo'}.with_indifferent_access }
  let(:user) { {uid: uid, email: uid, last_name: 'Pina', first_name: 'Agustín'}.with_indifferent_access }

  before { Classroom::Database.clean! }
  before { Classroom::Collection::Users.upsert_permissions! uid, old_permissions }
  before { Classroom::Collection::Organizations.insert!({name: 'example'}.wrap_json) }

  describe 'execute!' do

    context 'save new permissions' do
      before do
        expect(Classroom::Event::UserChanged).to receive(:student_added)
        expect(Classroom::Event::UserChanged).to receive(:teacher_added)
        expect(Classroom::Event::UserChanged).to receive(:student_removed)
      end
      before { Classroom::Event::UserChanged.execute! event }

      it { expect(Classroom::Collection::Organizations.all.map(&:name)).to include 'example' }
      it { expect(Classroom::Event::UserChanged.changes['example'].map(&:description)).to eq %w(student_removed student_added teacher_added) }
      it { expect(Mumukit::Auth::Permissions::Diff.diff(old_permissions, new_permissions).as_json)
             .to json_like(changes: [
               {role: 'student', grant: 'example/foo', type: 'removed'},
               {role: 'student', grant: 'example/bar', type: 'added'},
               {role: 'teacher', grant: 'example/foo', type: 'added'}]) }

    end

    context 'update models' do
      before do
        Course.create! organization: 'example', slug: 'example/foo'
        Course.create! organization: 'example', slug: 'example/bar'
        Classroom::Collection::Students.for('example', 'foo').insert! user
        Classroom::Collection::CourseStudents.for('example').insert!({course: {uid: 'example/foo'}, student: user})
      end
      before { Classroom::Event::UserChanged.execute! event }

      let(:user2) { user.merge(social_id: 'foo').except(:first_name) }
      let(:event) { {user: user2.merge(permissions: new_permissions)} }

      let(:student_foo_fetched) { Classroom::Collection::Students.for('example', 'foo').find_by(uid: uid) }
      let(:student_bar_fetched) { Classroom::Collection::Students.for('example', 'bar').find_by(uid: uid) }
      let(:teacher_foo_fetched) { Classroom::Collection::Teachers.for('example', 'foo').find_by(uid: uid) }

      it { expect(student_foo_fetched.detached).to eq true }
      it { expect(student_foo_fetched.social_id).to eq 'foo' }
      it { expect(student_foo_fetched.first_name).to eq 'Agustín' }

      it { expect(student_bar_fetched.as_json(except: [:created_at])).to eq user2.merge(organization: 'example', course: 'example/bar') }
      it { expect(student_bar_fetched.detached).to eq nil }

      it { expect(teacher_foo_fetched.as_json(except: [:created_at])).to eq user2.merge(organization: 'example', course: 'example/foo') }
    end

  end
end
