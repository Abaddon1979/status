# frozen_string_literal: true

# name: discourse-status
# about: Simple user status storage for Discord-style chat/theme
# version: 0.1
# authors: disorder
# url: https://github.com/Abaddon1979/disorder

enabled_site_setting :enable_user_status rescue nil

after_initialize do
  module ::DiscourseStatus
    class Engine < ::Rails::Engine
      engine_name "discourse_status"
      isolate_namespace DiscourseStatus
    end
  end

  # Routes for the status engine
  DiscourseStatus::Engine.routes.draw do
    # GET /status.json  -> current user's status/background (requires login)
    get "/" => "status#current"

    # GET /status/:username.json -> any user's status/background
    get "/:username" => "status#show", constraints: { username: RouteFormat.username }

    # POST/PUT /status.json -> update current user's status/background
    put "/" => "status#update"
    post "/" => "status#update"
  end

  # Mount engine at /chat-status (avoid clashing with core /status and /user-status)
  Discourse::Application.routes.append do
    mount ::DiscourseStatus::Engine, at: "/chat-status"
  end

  # Store status and background image in user custom fields
  User.register_custom_field_type("chat_status", :string)
  User.register_custom_field_type("chat_bg", :string)

  # Expose status and background image in the standard /u/:username.json response
  add_to_serializer(:user, :chat_status) do
    object.custom_fields["chat_status"]
  end

  add_to_serializer(:user, :chat_bg) do
    object.custom_fields["chat_bg"]
  end
end
