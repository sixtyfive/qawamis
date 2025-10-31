Rails.application.configure do
  config.content_security_policy do |p|
    # p.default_src :self
    # p.script_src  :self, ->{"'nonce-#{content_security_policy_nonce}'"}
    # p.style_src   :self
    # p.img_src     :self, :data
    # p.connect_src :self
    # p.font_src    :self, :data
    # p.frame_ancestors :none
  end
end
