require 'spec_helper'

describe Mumukit::Auth::PermissionsDiff do

  let(:permissions) { Mumukit::Auth::Permissions.parse({
    student: 'foo/bar:foo/baz',
    teacher: 'mumuki/foo:example/*',
  }) }

  let(:new_permissions) {{ student: 'foo/bar:foo/fiz' }}

  it 'diff' do
    expect(Mumukit::Auth::PermissionsDiff.diff permissions, new_permissions).to eq ({
      'student' => {
        'added' => ['foo/fiz'],
        'removed' => ['foo/baz']
      },
      'teacher' => {
        'removed' => %w(mumuki/foo example/*)
      }
    })
  end

end
