require 'spec_helper'

describe Mumukit::Auth::Permissions::Diff do

  let(:permissions) { Mumukit::Auth::Permissions.parse student: 'foo/bar:foo/baz',
                                                       teacher: 'mumuki/foo:example/*' }
  let(:diff) { Mumukit::Auth::Permissions::Diff.diff permissions, new_permissions }
  
  describe Mumukit::Auth::Permissions::Change do
    context 'single grant removed' do
      let(:change) { Mumukit::Auth::Permissions::Change.new :student, 'foo/bar'.to_mumukit_grant, :removed }

      it { expect(change.description).to eq 'student_removed' }
      it { expect(change.organization).to eq 'foo' }
    end

    context 'organization grant added' do
      let(:change) { Mumukit::Auth::Permissions::Change.new :teacher, 'bar/*'.to_mumukit_grant, :added }

      it { expect(change.description).to eq 'teacher_added' }
      it { expect(change.organization).to eq 'bar' }
    end
  end

  describe '.diff' do
    context 'student and teacher changed' do
      let(:new_permissions) { {student: 'foo/bar:foo/fiz'} }

      it { expect(diff.as_json).to json_like(changes: [{role: 'student', grant: 'foo/baz', type: 'removed'},
                                                       {role: 'student', grant: 'foo/fiz', type: 'added'},
                                                       {role: 'teacher', grant: 'mumuki/foo', type: 'removed'},
                                                       {role: 'teacher', grant: 'example/*', type: 'removed'}]) }
    end

    context 'no changes' do
      let(:new_permissions) { permissions }
      it { expect(diff).to be_empty }
    end

    context 'overlapped permissions' do
      let(:new_permissions) { {teacher: 'mumuki/foo:example/*:foo/*'} }

      it { expect(diff.as_json).to json_like({changes: [{role: 'student', grant: 'foo/bar', type: 'removed'},
                                                        {role: 'student', grant: 'foo/baz', type: 'removed'},
                                                        {role: 'teacher', grant: 'foo/*', type: 'added'}]}) }
    end

    context 'everything removed' do
      let(:new_permissions) { {} }

      it { expect(diff.as_json).to json_like({changes: [{role: 'student', grant: 'foo/bar', type: 'removed'},
                                                        {role: 'student', grant: 'foo/baz', type: 'removed'},
                                                        {role: 'teacher', grant: 'mumuki/foo', type: 'removed'},
                                                        {role: 'teacher', grant: 'example/*', type: 'removed'}]}) }

    end
  end

  describe '#changes_by_organization' do
    let(:diff) { Mumukit::Auth::Permissions::Diff.diff({student: 'foo/bar:zaraza/*', teacher: 'foo/baz:goo/baz'},
                                                       {student: 'zaraza/*', owner: 'foobar/*'}) }

    it { expect(diff.changes_by_organization.size).to eq 3 }

    it { expect(diff.changes_by_organization['foo'].size).to eq 2 }
    it { expect(diff.changes_by_organization['foobar'].size).to eq 1 }
    it { expect(diff.changes_by_organization['goo'].size).to eq 1 }
  end
end
