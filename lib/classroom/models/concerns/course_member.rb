module CourseMember

  def ensure_not_exists!(query)
    existing_members = where(query)
    return unless existing_members.exists?
    raise Classroom::CourseMemberExistsError, {existing_members: existing_members.map(&:uid)}.to_json
  end

end
