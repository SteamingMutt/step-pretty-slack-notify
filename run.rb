#!/usr/bin/env ruby

require "slack-notifier"

# These environment variables are required/optional for pretty-slack-notify step.
webhook_url = ENV["WERCKER_PRETTY_SLACK_NOTIFY_WEBHOOK_URL"] || ""
channel     = ENV["WERCKER_PRETTY_SLACK_NOTIFY_CHANNEL"]     || ""
username    = ENV["WERCKER_PRETTY_SLACK_NOTIFY_USERNAME"]    || ""
branches    = ENV["WERCKER_PRETTY_SLACK_NOTIFY_BRANCHES"]    || ""
notify_on   = ENV["WERCKER_PRETTY_SLACK_NOTIFY_NOTIFY_ON"]   || ""
abort "Please specify the your slack webhook url" if webhook_url.empty?
username = "Wercker"                              if username.empty?

# See for more details about environment variables that we can use in our steps.
# http://devcenter.wercker.com/docs/environment-variables/available-env-vars
git_owner         = ENV["WERCKER_GIT_OWNER"]
git_repo          = ENV["WERCKER_GIT_REPOSITORY"]
app_name          = "#{git_owner}/#{git_repo}"
app_url           = ENV["WERCKER_APPLICATION_URL"]
build_url         = ENV["WERCKER_BUILD_URL"] || ""
run_url           = ENV["WERCKER_RUN_URL"]   || ""
git_commit        = ENV["WERCKER_GIT_COMMIT"]
git_branch        = ENV["WERCKER_GIT_BRANCH"]
started_by        = ENV["WERCKER_STARTED_BY"]
result            = ENV["WERCKER_RESULT"]
deploy_url        = ENV["WERCKER_DEPLOY_URL"]
deploytarget_name = ENV["WERCKER_DEPLOYTARGET_NAME"]

if !branches.empty? && Regexp.new(branches) !~ git_branch
  puts "'#{git_branch}' branch did not match notify branches /#{branches}/"
  puts "Skipped to notify"
  exit
end

unless notify_on.empty? || notify_on == result
  puts "Result '#{result}' did not match notify condition '#{notify_on}'"
  puts "Skipped to notify"
  exit
end

# Wercker's new stack uses WERCKER_RUN_URL instead of WERCKER_BUILD_URL
if build_url.empty? && !run_url.empty?
  build_url = run_url
end

def deploy?
  ENV["DEPLOY"] == "true"
end

def build_message(app_name, app_url, build_url, git_commit, git_branch, started_by, result)
  "[build](#{build_url}) (#{git_commit[0,8]}) for [#{app_name}](#{app_url}) by #{started_by} has #{result} on #{git_branch}"
end

def deploy_message(app_name, app_url, deploy_url, deploytarget_name, git_commit, git_branch, started_by, result)
  "[deploy](#{deploy_url}) (#{git_commit[0,8]}) to #{deploytarget_name} for [#{app_name}](#{app_url}) by #{started_by} has #{result} on #{git_branch}"
end

def icon_url
  "https://secure.gravatar.com/avatar/a08fc43441db4c2df2cef96e0cc8c045?s=140"
end

notifier = Slack::Notifier.new(
  webhook_url,
  username: username,
)

message = deploy? ?
  deploy_message(app_name, app_url, deploy_url, deploytarget_name, git_commit, git_branch, started_by, result) :
  build_message(app_name, app_url, build_url, git_commit, git_branch, started_by, result)

notifier.channel = '#' + channel unless channel.empty?

res = notifier.ping(
  message,
  icon_url: icon_url,
)

case res.code
when "404" then abort "Webhook url not found."
when "500" then abort res.read_body
else puts "Notified to Slack #{notifier.channel}"
end
