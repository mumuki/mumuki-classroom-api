require 'spec_helper'

describe Mumukit::Auth::Permissions::Diff do

  let(:permissions) { Mumukit::Auth::Permissions.parse(
    student: 'foo/bar:foo/baz',
    teacher: 'mumuki/foo:example/*',
  ) }
  let(:diff) { Mumukit::Auth::Permissions::Diff.diff permissions, new_permissions }

  context 'student and teacher changed' do
    let(:new_permissions) { {student: 'foo/bar:foo/fiz'} }

    it { expect(diff).to eq(
                           'student' => {
                             'added' => ['foo/fiz'],
                             'removed' => ['foo/baz']
                           },
                           'teacher' => {
                             'removed' => %w(mumuki/foo example/*)
                           }) }
  end

  context 'no changes' do
    let(:new_permissions) { permissions }
    it { expect(diff).to eq(
                           'student' => {},
                           'teacher' => {}
                         ) }
  end


  context 'everything removed' do
    let(:new_permissions) { {} }
    it { expect(diff).to eq(
                           'student' => {
                             "removed" => %w(foo/bar foo/baz)
                           },
                           'teacher' => {
                             'removed' => %w(mumuki/foo example/*)
                           }) }
  end
end
