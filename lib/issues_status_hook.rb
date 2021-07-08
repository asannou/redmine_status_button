
class IssueStatusHook < Redmine::Hook::ViewListener
	CURRENT_USER = "__current_user__"
	AUTHOR = "__author__"

	def controller_issues_new_before_save(context={})
		update_issues(context[:issue])
	end
	
	def controller_issues_edit_before_save(context={})
		return if !StatusButton::Hooks.is_open?(context[:issue].project)
		# TODO: 检测status变更（需要用到issues@attributes_before_change）
		update_issues(context[:issue])
	end
	
	def update_issues(issue)
		plugin = Redmine::Plugin.find(:status_button)
		setting = Setting["plugin_#{plugin.id}"] || plugin.settings['default']
		status_to_user = {}
		setting['status_assigned_to'].each { |s, a|
			status_to_user[Integer(s)] = case a
				when CURRENT_USER then User.current.id
				when AUTHOR then issue.author_id
				else a && User.find_by_login(a)&.id
			end
		}
		status_to_user
		issue.assigned_to_id = status_to_user[issue.status_id] if status_to_user[issue.status_id]
		issue.watcher_user_ids = issue.watcher_user_ids | status_to_user.map{|s,u| u} if setting['add_watcher']
	end
end
