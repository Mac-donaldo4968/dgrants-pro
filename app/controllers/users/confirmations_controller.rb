class Users::ConfirmationsController < Devise::ConfirmationsController
  # Remove the first skip_before_filter (:require_no_authentication) if you
  # don't want to enable logged users to access the confirmation page.
  skip_before_filter :require_no_authentication
  skip_before_filter :authenticate_user!

  # POST /resource/confirmation
  def create
    user = User.where(email: params[:user][:email]).first
    if user.present?
      user.update_attributes(confirmed_at: nil)
      user.send_confirmation_instructions
    end
    sign_out(:user)
    self.resource = User.new
    # sign_out_and_redirect(resource_name)
    # flash[:notice] = t("devise.confirmations.send_paranoid_instructions")
    render 'devise/confirmations/sent_confirmation'
  end

  # PUT /resource/confirmation
  def update
    with_unconfirmed_confirmable do
      if @confirmable.has_no_password?
        @confirmable.attempt_set_password(params[:user])
        if @confirmable.valid? && @confirmable.password_match?
          do_confirm
        else
          do_show
          @confirmable.errors.clear # so that we won't render :new
        end
      else
        self.class.add_error_on(self, :email, :password_already_set)
      end
    end

    if !@confirmable.errors.empty?
      render 'devise/confirmations/new' # Change this is you don't have the views on default path
    end
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    with_unconfirmed_confirmable do
      if @confirmable.has_no_password?
        do_show
      else 
        do_confirm
      end
    end
    if !@confirmable.errors.empty?
      if user_signed_in?
        sign_out(:user)
      end
      self.resource = @confirmable
      render 'devise/confirmations/new' # Change this if you don't have the views on default path
    else
      user = @confirmable
    end
  end

  protected

  def with_unconfirmed_confirmable
    original_token = params[:confirmation_token]
    confirmation_token = Devise.token_generator.digest(User, :confirmation_token, original_token)
    @confirmable = User.find_or_initialize_with_error_by(:confirmation_token, confirmation_token)
    if !@confirmable.new_record?
      @confirmable.only_if_unconfirmed {yield}
    end    
  end

  def do_show
    @confirmation_token = params[:confirmation_token]
    @requires_password = true
    self.resource = @confirmable
    render 'devise/confirmations/show' # Change this if your don't have the views on default path    
  end

  def do_confirm
    # @confirmable.confirm!
    # set_flash_message :notice, :confirmed
    sign_in_and_redirect(resource_name, @confirmable)
  end
end