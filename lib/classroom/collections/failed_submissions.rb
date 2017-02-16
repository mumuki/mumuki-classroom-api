class Classroom::Collection::FailedSubmissions < Classroom::Collection::OrganizationCollection

  def initialize(organization)
    super organization
    create_index id: 1
  end

  def find_by_uid(uid)
    where query('submitter.uid': uid)
  end

  private

  def pk
    super.merge 'submitter.uid': 1
  end

  def wrap(it)
    Mumukit::Service::Document.new it
  end

end
