# frozen_string_literal: true

module DiscourseStatus
  class StatusController < ::ApplicationController
    requires_login except: [:show]

    # GET /status.json  (current user's status/background)
    def current
      user = current_user
      raise Discourse::InvalidAccess.new unless user

      render_json_dump(
        username: user.username,
        status: user.custom_fields["chat_status"] || "",
        background_url: user.custom_fields["chat_bg"] || ""
      )
    end

    # GET /status/:username.json
    def show
      user = fetch_user_from_params
      raise Discourse::NotFound unless user

      render_json_dump(
        username: user.username,
        status: user.custom_fields["chat_status"] || "",
        background_url: user.custom_fields["chat_bg"] || ""
      )
    end

    # POST/PUT /status.json
    # Params: { status: "text", background_url: "https://..." }
    # Both fields are optional; only provided ones are updated.
    def update
      user = current_user
      raise Discourse::InvalidAccess.new unless user

      status_param = params[:status]
      bg_param = params[:background_url] || params[:bg]

      if status_param
        status = status_param.to_s[0...280] # simple length cap
        user.custom_fields["chat_status"] = status
      end

      if bg_param
        background_url = bg_param.to_s[0...1024]
        user.custom_fields["chat_bg"] = background_url
      end

      user.save_custom_fields

      render_json_dump(
        success: true,
        username: user.username,
        status: user.custom_fields["chat_status"] || "",
        background_url: user.custom_fields["chat_bg"] || ""
      )
    end

    private

    def fetch_user_from_params
      username = params[:username]
      return nil if username.blank?

      User.find_by(username_lower: username.to_s.downcase)
    end
  end
end
