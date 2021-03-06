class ChallengesController < ApplicationController
  before_action :enforce_access
  before_action :find_challenge, except: :index
  def index
    @categories = @game.categories.includes(:challenges).order(:name)
    @challenges = @game.challenges
    @divisions = @game.divisions
    @solvedChallenges = @game.solved_challenges
    # Only exists for the purpose of providing an active tab for admins.
    @active_division = @divisions.first
    @title = 'Challenges'
    @subtitle = %(#{pluralize(@challenges.count, 'challenge')} in
    #{pluralize(@categories.count, 'category')})
  end

  def show
    is_admin = current_user.is_a?(Admin)
    # Accept the flag via GET request if the current user is an admin.
    @admin_flag = Flag.find(params[:flag]) if is_admin && params[:flag]
    @solved = @challenge.solved_by_user?(current_user)

    @solved_video_url = @challenge.get_video_url_for_flag(current_user)
    # Get video URL for admins
    @solved_video_url = @admin_flag.video_url if @admin_flag
    @solved_by = SolvedChallenge.where('challenge_id = :challenge',
                                       challenge: @challenge).order(:created_at).reverse_order

    flash.now[:success] = I18n.t('flag.accepted') if @solved || @admin_flag
    @title = @challenge.name
    @subtitle = pluralize(@challenge.point_value, 'point')
    @submitted_flags = to_timeline SubmittedFlag.where('challenge_id=?',
                                                       params[:id]).group_by { |sf| sf.updated_at.change(sec: 0) }
  end

  def submit_flag
    # get variables
    flag = params[:challenge][:submitted_flag]
    is_player = current_user.is_a?(Player)

    # audit log
    if is_player
      SubmittedFlag.create(player: current_user, challenge: @challenge, text: flag)
    end

    # handle flag
    flag_found = @challenge.flags.find { |flag_obj| flag_obj.flag.casecmp(flag).zero? }

    if flag_found

      # Make API call if one is specified. This throws away any failed requests
      # since we really don't care that much if the actions really happen. The
      # player properly being credited their points is more important.
      @api_url = flag_found.api_request
      Thread.new do
        begin
          Net::HTTP.get(URI.parse(@api_url)) if @api_url
        # Could list all the execeptions, most advice advocates to move
        # to a 3rd party HTTP library that has errors derived from a common
        # superclass
        rescue StandardError
          redirect_to @challenge, alert: I18n.t('http_error')
        end
      end

      if is_player
        # Because a user solved it, increase the total shares by shares_increment
        shares_for_user = @challenge[:share_increment]
        current_total = 0
        @game.solved_challenges.each do |challenge|
          current_total += challenge.share_number
        end
        @challenge[:shares] = shares_for_user
        @challenge.save
        if @challenge[:solved_at].nil?
          @challenge[:solved_at] = DateTime.current
          @challenge.save
        end

        SolvedChallenge.create(player: current_user, challenge: @challenge, flag: flag_found,
                               division: current_user.division, share_number: @challenge[:share_increment])

         redirect_to @challenge
      else
        redirect_to challenge_url(@challenge, flag: flag_found)
        # flash.now[:notice] = I18n.t('teams.full_team') if team_captain? && !team_editable?
        # redirect_to @team, notice: I18n.t('teams.create_successful')
      end
    else
      redirect_to @challenge, flash: { error: Rails.configuration.wrong_flag_messages.sample }
    end
  end

  private

  def find_challenge
    @challenge = @game.challenges.find(params[:id])
  end
end
