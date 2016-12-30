class Hash
  def to_mumukit_permissions
    Mumukit::Auth::Permissions.parse self
  end
end

class Mumukit::Auth::Permissions
  def to_mumukit_permissions
    self
  end
end



module Mumukit::Auth::Permissions::Diff
  def self.diff(old_permissions, new_permissions)
    old_perms = old_permissions.to_mumukit_permissions
    new_perms = new_permissions.to_mumukit_permissions

    {}.with_indifferent_access.tap do |diff|
      Mumukit::Auth::Roles::ROLES.each do |role|
        grants(role, old_perms, new_perms).each do |grant_s|
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
    old_perms.has_permission?(role, grant_s) && !new_perms.has_permission?(role, grant_s)
  end

  def self.add_grant?(grant_s, new_perms, old_perms, role)
    !old_perms.has_permission?(role, grant_s) && new_perms.has_permission?(role, grant_s)
  end

  def self.grants(role, *permissions)
    permissions.flat_map { |it| it.grant_strings_for(role) }
  end
end
