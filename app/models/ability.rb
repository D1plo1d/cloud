class Ability
  include CanCan::Ability

  def can_via_queue(abilities, resource, roles)
    roles.each do |current_role|
      can abilities, resource do |m|
        # yields model instance, role
        yield(m, current_role)
      end
    end
  end

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)


    # Print Queue
    queue_admin_abilities = [:manage_users, :manage_profiles, :manage_printers, :manage_print_jobs, :edit, :destroy]

    can_via_queue queue_admin_abilities, PrintQueue, [:owner, :admin] do |print_queue, role|
      user.has_role?(:sysadmin) or PrintQueue.with_role(role, user).include? print_queue
    end


    # Print Queue Child Objects
    [GCodeProfile, PrintJob, Printer].each do |resource|
      can_via_queue [:create, :edit, :destroy], resource, [:owner, :admin] do |instance, role|
        user.has_role?(:sysadmin) or PrintQueue.with_role(role, user).map(&:id).include? instance.print_queue_id
      end
    end


    # Users
    can [:edit, :destroy, :create_print_queues], User do |u|
      user.has_role?(:sysadmin) or user == u
    end

    # How I wish rolify worked:
    # can :manage_users, PrintQueue, PrintQueue.with_role([:owner, :admin], user)

    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
