# frozen_string_literal: true

# name: status
# about: Simple user status storage for Discord-style chat/theme
# version: 0.1
# authors: disorder
# url: https://github.com/Abaddon1979/disorder

enabled_site_setting :enable_user_status rescue nil

after_initialize do
  # Force-load the status controller so DiscourseStatus::StatusController is defined.
  # Using an explicit `load` with a full path avoids Zeitwerk/bootsnap load path issues.
  # __dir__ is the plugin root; the controller lives under ./app/controllers/...
  load File.expand_path("app/controllers/discourse_status/status_controller.rb", __dir__)

  # Direct routes under the main Discourse application, mounted at /chat-status.
  # This avoids any Rails::Engine routing quirks and guarantees that
  #   /chat-status.json
  #   /chat-status/:username.json
  # are available when the plugin is enabled.
  Discourse::Application.routes.append do
    # GET /chat-status.json  -> current user's status/background (requires login)
    get "/chat-status" => "discourse_status/status#current"

    # GET /chat-status/:username.json -> any user's status/background
    get "/chat-status/:username" => "discourse_status/status#show", constraints: { username: RouteFormat.username }

    # POST/PUT /chat-status.json -> update current user's status/background
    put "/chat-status" => "discourse_status/status#update"
    post "/chat-status" => "discourse_status/status#update"
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
