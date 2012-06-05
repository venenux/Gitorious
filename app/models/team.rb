# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
class Team

  def self.group_implementation
    @group_implementation
  end

  def self.group_implementation=(klass)
    @group_implementation = klass
  end

  self.group_implementation = GitoriousConfig["group_implementation"].constantize

  class GroupFinder
    def paginate_all(current_page=nil)
      Group.paginate(:all, :page => current_page)
    end

    def find_by_name!(name)
      includes = [:projects, :repositories, :committerships, :members]
      Group.find_by_name!(name,:include => includes)
    end

    def new_group(params={})
      Group.new(params)
    end

    def create_group(params, user)
      group = new_group(params)
      group.transaction do
        group.creator = user
        group.save!
        group.memberships.create!({
            :user => user,
            :role => Role.admin,
          })
      end
      return group
    end
  end

  class LdapGroupFinder
    def paginate_all(current_page = nil)
      LdapGroup.paginate(:all, :page => current_page)
    end

    def find_by_name!(name)    
      includes = [:projects, :repositories, :committerships]
      LdapGroup.find_by_name!(name,:include => includes)
    end

    def new_group(params={})
      LdapGroup.new
    end

    def create_group(params, user)
      group = new_group(params)
      group.transaction do
        group.creator = user
        group.save!
      end
      return group
    end
  end

  # Return a (class level) finder
  def self.group_finder
    group_implementation == LdapGroup ? LdapGroupFinder.new : GroupFinder.new
  end
  
  def self.paginate_all(current_page = nil)
    group_finder.paginate_all
  end

  def self.find_by_name!(name)
    group_finder.find_by_name!(name)
  end

  def self.memberships(group)
    if group.is_a?(Group)
      group.memberships.find(:all, :include => [:user, :role])
    else
      []
    end
  end

  def self.events(group, page)
    if group.is_a?(Group)
      group.events(page)
    else
      []
    end
  end

  def self.new_group
    group_finder.new_group
  end

  def self.create_group(params, user)
    group_finder.create_group(group_params(params), user)
  end

  def self.group_params(params)
    params.key?(:ldap_group) ? params[:ldap_group] : params[:group]
  end

  
  def self.update_group(group, params)
    params = group_params(params)
    group.description = params[:description]
    group.avatar = params[:avatar]
    group.ldap_group_names = params[:ldap_group_names] if params.key?(:ldap_group_names)
    group.save!
  end

  class DestroyGroupError < StandardError
  end
  
  def self.destroy_group(name, user)
    group = group_finder.find_by_name! name
    unless user.is_admin? 
      raise DestroyGroupError, "You're not admin" unless group_admin?(group, user)
      raise DestroyGroupError, "Teams with current members or projects cannot be deleted" unless group.deletable?
    end
    group.destroy
  end

  def self.group_admin?(group, user)
    return false unless user.is_a? User
    role = group.user_role(user)
    role && role.admin?
  end

  def self.delete_avatar(group)
    group.avatar.destroy
    group.save
  end

  def self.can_have_members?(group)
    group.is_a?(Group) 
  end


end