module SimpleAuth
  module Controller
    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
      end
    end
    
    module ClassMethods
      def activate_simple_auth!(*submodules)
        Config.submodules = submodules
        yield Config if block_given?
        
        self.class_eval do
          include InstanceMethods
          if Config.submodules.include?(:remember_me)
            include RememberMeMethods
          end
        end
      end
    end
    
    module InstanceMethods
      def login(username,password)
        user = User.authenticate(username,password)
        if user
          reset_session # protect from session fixation attacks
          session[:user_id] = user.id
          user
        end
      end
      
      def logout
        if logged_in?
          reset_session
        end
      end
      
      def logged_in?
        session[:user_id]
      end
      
      def logged_in_user
        @logged_in_user ||= login_from_session unless @logged_in_user == false # || login_from_basic_auth || login_from_cookie)
      end
      
      protected
      
      def login_from_session
        (User.find_by_id(session[:user_id]) if session[:user_id]) || false
      end
    end
    
    module RememberMeMethods
      def remember_me!
        logged_in_user.remember_me!
        send(:"#{Config.cookies_attribute_name}")[:remember_me_token] = { :value => logged_in_user.remember_me_token, :expires => logged_in_user.remember_me_token_expires_at }        
      end
      
      def forget_me!
        logged_in_user.forget_me!
        self.send(:"#{Config.cookies_attribute_name}")[:remember_me_token] = nil
      end
    end
    
    module Config
      class << self
        attr_accessor :submodules,
                      :session_attribute_name,
                      :cookies_attribute_name
        
        def reset!
          @session_attribute_name = :session
          @cookies_attribute_name = :cookies
        end
      
      end
      reset!
    end
  end
end