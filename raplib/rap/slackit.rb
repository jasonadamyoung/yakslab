require 'slack-notifier'
module Rap
  class Slackit

    attr_accessor :message, :attachment, :slack, :icon_emoji

    def initialize(options = {})
      username = options[:username] || "RapBot"
      channel = options[:channel] || Rap.settings.slack_channel
      @slack = Slack::Notifier.new(Rap.settings.slack_webhook) do
        defaults(channel: channel, username: username)
      end
      @message = options[:message] || ''
      @attachment = options[:attachment]
      @icon_emoji = options[:icon_emoji]
      self
    end

    def post
      post_parameters = {}
      if(self.attachment)
        post_parameters[:attachments] = [self.attachment]
      end

      if(self.icon_emoji)
        post_parameters[:icon_emoji] = self.icon_emoji
      else
        post_parameters[:icon_emoji] = ':crystal_ball:'
      end

      self.slack.ping(self.message, post_parameters)

    end

    def self.post(options = {})
      if(notification = self.new(options))
        notification.post
      end
    end

    def self.post_command_message(command)
      self.post(message: "#{Rap::Utils.whoami} is executing `#{command}` from #{Rap::Utils.whereami}")
    end

  end
end
