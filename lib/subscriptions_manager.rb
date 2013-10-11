##
# This class has methods related to recovering and updating the cached unread entries count
# for feeds and folders.

class SubscriptionsManager

  ##
  # Add a new subscription of a user to a feed. The cached count of unread entries will be
  # initialized to the current number of entries in the feed, thanks to various model callbacks.
  #
  # Receives as arguments the suscribing user and the feed to which he's to be subscribed.
  #
  # If the user is already subscribed to the feed, an AlreadySubscribedError is raised.

  def self.add_subscription(feed, user)
    check_user_unsubscribed feed, user

    Rails.logger.info "subscribing user #{user.id} - #{user.email} to feed #{feed.id} - #{feed.fetch_url}"
    feed_subscription = FeedSubscription.new feed_id: feed.id
    user.feed_subscriptions << feed_subscription
  end

  ##
  # Unsubscribes a user from a feed.
  #
  # Receives as argument the feed to unsubscribe, and the user who is unsubscribing.
  #
  # If the user is not subscribed to the feed, a NotSubscribedError is raised.

  def self.remove_subscription(feed, user)
    check_user_subscribed feed, user

    feed_subscription = FeedSubscription.where(feed_id: feed.id, user_id: user.id).first
    Rails.logger.info "unsubscribing user #{user.id} - #{user.email} from feed #{feed.id} - #{feed.fetch_url}"
    user.feed_subscriptions.delete feed_subscription

    return nil
  end

  ##
  # Retrieve the count of unread entries in a feed for a given user. This count is not
  # calculated when this method is invoked, but rather it is retrieved from a pre-calculated
  # field in the database.
  #
  # Receives as arguments:
  # - feed from which to retrieve the count
  # - user for whom the unread entries count is to be retrieved
  #
  # Returns a positive (or zero) integer with the count.
  # If the user is not actually subscribed to the feed, a NotSubscribedError is raised.

  def self.feed_unread_count(feed, user)
    check_user_subscribed feed, user

    feed_subscription = user.feed_subscriptions.where(feed_id: feed.id).first
    return feed_subscription.unread_entries
  end

  ##
  # Retrieve the count of unread entries in a folder owned by a given user. This count is not
  # calculated when this method is invoked, but rather it is retrieved from a pre-calculated
  # field in the database.
  #
  # Receives as arguments:
  # - folder for which to retrieve the count. It accepts the special value 'all' instead of a Folder instance;
  # in this case the total number of unread entries in all the feeds subscribed by the user is returned (regardless
  # of the folder to which each feed belongs, and including feeds which are not in a folder).
  # - user to whom the folder belongs
  #
  # In all cases the folder or user instance is reloaded from the database, because before calling this method
  # the unread_entries column in the database may have changed. Reloading here simplifies code, avoiding the
  # need to always reload before invoking this method.
  #
  # Returns a positive (or zero) integer with the count.

  def self.folder_unread_count(folder, user)
    unread_count = 0

    if folder == 'all'
      unread_count = 0
      user.feeds.each do |f|
        unread_count += user.feed_unread_count f
      end
    else
      unread_count = folder.reload.unread_entries
    end

    return unread_count
  end

  ##
  # Increment the count of unread entries in a feed for a given user.
  #
  # Receives as arguments:
  # - increment: how much to increment the count. Optional, has default value of 1.
  # - feed which count will be incremented
  # - user for which the count will be incremented
  #
  # If the user is not actually subscribed to the feed, a NotSubscribedError is raised.

  def self.feed_increment_count(feed, user, increment=1)
    check_user_subscribed feed, user

    feed_subscription = user.feed_subscriptions.where(feed_id: feed.id).first
    Rails.logger.debug "Incrementing unread entries count for user #{user.id} - #{user.email}, feed #{feed.id} - #{feed.fetch_url}. Current: #{feed_subscription.unread_entries}, incremented by #{increment}"
    feed_subscription.unread_entries += increment
    feed_subscription.save!
  end

  ##
  # Decrement the count of unread entries in a feed for a given user.
  #
  # Receives as arguments:
  # - decrement: how much to decrement the count. Optional, has default value of 1.
  # - feed which count will be decremented
  # - user for which the count will be decremented
  #
  # If the user is not actually subscribed to the feed, a NotSubscribedError is raised.

  def self.feed_decrement_count(feed, user, decrement=1)
    self.feed_increment_count feed, user, -decrement
  end

  private

  ##
  # Find out if a user is subscribed to a feed.
  #
  # Receives as arguments the feed and the user to check.
  #
  # Returns true if the user is subscribed to the feed, false otherwise.

  def self.user_subscribed?(feed, user)
    if FeedSubscription.exists? feed_id: feed.id, user_id: user.id
      return true
    else
      return false
    end
  end

  ##
  # Check that a user is subscribed to a feed.
  #
  # Receives as arguments the feed and user to check.
  #
  # If the user is not subscribed to the feed a NotSubscribedError is raised.
  # Otherwise nil is returned.

  def self.check_user_subscribed (feed, user)
    if !user_subscribed? feed, user
      Rails.logger.warn "User #{user.id} - #{user.id} tried to change unread entries count for feed #{feed.id} - #{feed.fetch_url} to which he is not subscribed"
      raise NotSubscribedError.new
    end
    return nil
  end


  ##
  # Check that a user is not subscribed to a feed.
  #
  # Receives as arguments the feed and user to check.
  #
  # If the user is subscribed to the feed a NotSubscribedError is raised.
  # Otherwise nil is returned.

  def self.check_user_unsubscribed (feed, user)
    if user_subscribed? feed, user
      Rails.logger.warn "User #{user.id} - #{user.id} tried to subscribe to feed #{feed.id} - #{feed.fetch_url} to which he is already subscribed"
      raise AlreadySubscribedError.new
    end
    return nil
  end
end