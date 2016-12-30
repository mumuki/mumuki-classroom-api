module Mumukit::Auth::PermissionsDiff

  def self.diff(old_permissions, new_permissions)
    old_perms = Mumukit::Auth::Permissions.parse(old_permissions.as_json)
    new_perms = Mumukit::Auth::Permissions.parse(new_permissions.as_json)

    {}.with_indifferent_access.tap do |diff|
      Mumukit::Auth::Roles::ROLES.each do |role|
        grants(role, old_perms, new_perms).each do |grant|
          grant_s = grant.to_s
          diff[role] ||= {}.with_indifferent_access
          add_grant(diff, role, :added, grant_s) if add_grant?(grant_s, new_perms, old_perms, role)
          add_grant(diff, role, :removed, grant_s) if remove_grant?(grant_s, new_perms, old_perms, role)
        end
      end
    end
  end

  private

  def self.add_grant(diff, role, type, grant)
    (diff[role][type] ||= []) << grant
  end

  def self.remove_grant?(grant_s, new_perms, old_perms, role)
    old_perms.has_permission?(role, grant_s) and !new_perms.has_permission?(role, grant_s)
  end

  def self.add_grant?(grant_s, new_perms, old_perms, role)
    !old_perms.has_permission?(role, grant_s) and new_perms.has_permission?(role, grant_s)
  end

  def self.grants(role, *permissions)
    permissions.reduce([]) { |accum, perm| accum | grants_from(role, perm) }
  end

  def self.grants_from(role, permission)
    permission.scope_for(role)&.grants || []
  end

end
