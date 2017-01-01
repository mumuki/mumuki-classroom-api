require 'spec_helper'

describe Classroom::PermissionsPersistence::Mongo do

  after { Classroom::Database.clean! }

  let(:uid) { 'agus@mumuki.org' }
  let(:mongo) { Classroom::PermissionsPersistence::Mongo.new }
  let(:agus_permissions) { mongo.get uid }

  before { mongo.set! uid, {student: 'foo/bar'} }

  it { expect(agus_permissions.student? 'foo/bar').to eq true }
  it { expect(agus_permissions.student? 'bar/foo').to eq false }

end
