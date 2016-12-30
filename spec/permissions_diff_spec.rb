require 'spec_helper'

describe Mumukit::Auth::Permissions::Diff do

  let(:permissions) { Mumukit::Auth::Permissions.parse(
    student: 'foo/bar:foo/baz',
    teacher: 'mumuki/foo:example/*',
  ) }
  let(:diff) { Mumukit::Auth::Permissions::Diff.diff permissions, new_permissions }

  context 'student and teacher changed' do
    let(:new_permissions) { {student: 'foo/bar:foo/fiz'} }

    it { expect(diff).to json_like(changes: [{role: 'student', grant: 'foo/baz', change_type: 'removed'},
                                             {role: 'student', grant: 'foo/fiz', change_type: 'added'},
                                             {role: 'teacher', grant: 'mumuki/foo', change_type: 'removed'},
                                             {role: 'teacher', grant: 'example/*', change_type: 'removed'}]) }
  end

  context 'no changes' do
    let(:new_permissions) { permissions }
    it { expect(diff).to be_empty }
  end

  context 'everything removed' do
    let(:new_permissions) { {} }
    it { expect(diff).to json_like({changes: [{role: 'student', grant: 'foo/bar', change_type: 'removed'},
                                              {role: 'student', grant: 'foo/baz', change_type: 'removed'},
                                              {role: 'teacher', grant: 'mumuki/foo', change_type: 'removed'},
                                              {role: 'teacher', grant: 'example/*', change_type: 'removed'}]}) }
  end
end
