class Hash
  def to_mumukit_permissions
    Mumukit::Auth::Permissions.parse self
  end
end

class Mumukit::Auth::Permissions
  def to_mumukit_permissions
    self
  end

  def grants_for(role)
    scope_for(role).grants
  end
end

class Mumukit::Auth::Permissions
  class Change
    attr_accessor :role, :grant, :type

    def initialize(role, grant, change_type)
      @role = role
      @grant = grant
      @type = change_type
    end

    def description
      "#{role}_#{type}"
    end

    def organization
      granted_slug.organization
    end

    def granted_slug
      grant.to_mumukit_slug
    end
  end

  class Diff
    attr_accessor :changes

    def initialize
      @changes = []
    end

    def changes_by_organization
      changes.group_by(&:organization)
    end

    def empty?
      changes.empty?
    end

    def compare_grants!(role, some_permissions, another_permissions, change_type)
      some_permissions
        .grants_for(role)
        .select { |grant| !another_permissions.role_allows?(role, grant) }
        .each { |grant| changes << Change.new(role, grant, change_type) }
    end

    def self.diff(old_permissions, new_permissions)
      old_permissions = old_permissions.to_mumukit_permissions
      new_permissions = new_permissions.to_mumukit_permissions
      new.tap do |it|
        Mumukit::Auth::Roles::ROLES.each do |role|
          it.compare_grants! role, old_permissions, new_permissions, :removed
          it.compare_grants! role, new_permissions, old_permissions, :added
        end
      end
    end
  end
end
