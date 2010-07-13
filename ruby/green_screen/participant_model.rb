class Participant < ActiveRecord::Base

  belongs_to :event
  belongs_to :background
  belongs_to :image_profile

  has_many :views

  belongs_to :friend, :foreign_key => 'friend_id', :class_name => 'Participant'
  has_many :friends, :foreign_key => 'friend_id', :class_name => 'Participant'
  
  attr_accessor :reprocess

  uniquify :token

  has_attached_file :photo, :styles => {
      :large => '800x800>',
      :medium => '538x538>',
      :small => '250x250>',
      :thumbnail => '100x100>'
    }, 
    :processors => [:swap_back],
    :path => ":rails_root/public/system/:class/:token/:style.:extension",
    :url => "/system/:class/:token/:style.:extension"

  named_scope :attendees, :conditions => {:friend_id => nil}
  named_scope :friends, :conditions => 'friend_id > 0'
  named_scope :bounced, :conditions => "status LIKE 'Email bounced:%' OR status LIKE 'Mail error:%'"
  
  def image_profile
    ImageProfile.find_by_id(image_profile_id) || event.image_profile rescue nil
  end

  # Recursively finds friends, friends of friends, etc.
  def all_friends
    @all_friends ||= []
    friends.each do |f|
      @all_friends << f
      @all_friends << f.all_friends
    end
    @all_friends.flatten
  end

  def download_photo_url
    [APP['host'], 'photos', token, 'download'].join('/')
  end

  def email_with_name
    s = ''
    s += "\"#{name}\"" if name
    s += "<#{email}>"
    s
  end

  # Recursively find attendee's photo
  def friend_photo
    if friend.friend_id.nil?
      friend.photo
    else
      friend.friend_photo
    end
  end

  def friends_count
    all_friends.length
  end

  def invite message = ''
    begin
      if friend_id.nil?
        if NosMailer.deliver_invite_subject self
          update_attribute 'status', 'Invited'
        else
          update_attribute 'status', 'Mail error'
          return false
        end
      else
        if NosMailer.deliver_invite_friend self, message
          update_attribute 'status', 'Invited'
        else
          update_attribute 'status', 'Mail error'
          return false
        end
      end
    rescue Exception => e
      update_attribute 'status', "Mail error: #{e}"
      return false
    end
  end

  def participant_type
    if friend_id.nil?
      "Attended #{ event ? event.name : '?' }"
    else
      'Friend'
    end
  end

  def photo_url
    [APP['host'], 'photos', token].join('/')
  end
  
  def reprocess=(value)
    if value.to_i == 1
      photo.reprocess!
    end
  end

  def status
    if views.blank?
      read_attribute :status
    else
      "Viewed #{views.count} times"
    end
  end

  def url
    [APP['host'], token].join('/')
  end

  def self.recently_viewed
    a = View.recent.map {|v| v.participant }
  end

end
