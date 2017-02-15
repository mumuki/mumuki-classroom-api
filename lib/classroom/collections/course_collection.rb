class Classroom::Collection::CourseCollection < Classroom::Collection::OrganizationCollection

  def self.for(organization, course)
    self.new(organization, course)
  end

  def initialize(organization, course)
    super organization
    @course = course
  end

  def course
    @course
  end

  def course_slug
    "#{organization}/#{course}"
  end

  private

  def pk
    super.merge course: 1
  end

  def query(args = {})
    super({course: course_slug}.merge args)
  end

end
