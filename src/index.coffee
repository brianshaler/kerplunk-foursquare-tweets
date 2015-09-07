Promise = require 'when'

pattern = /\/\/foursquare\.com\/[a-z0-9\-_]+\/checkin\/([a-z0-9\-_]+)/i

module.exports = (System) ->
  ActivityItem = System.getModel 'ActivityItem'

  preSave = (item) ->
    return item unless item.platform == 'twitter' or item.platform == 'foursquare'
    if item.platform == 'foursquare'
      mpromise = ActivityItem
      .where
        platform: 'twitter'
        message: new RegExp "/checkin/#{item.data.id}"
      .findOne()
      Promise(mpromise).then (tweet) ->
        return item unless tweet
        tweet.activityOf = item._id
        Promise tweet.save()
        .then ->
          item.activity = [] unless item.activity?.length > 0
          item.activity.push tweet._id
          item
    else if pattern.test item.message
      match = item.message.match pattern
      mpromise = ActivityItem
      .where
        platform: 'foursquare'
        'data.id': match[1]
      .findOne()
      Promise(mpromise) (checkin) ->
        return item unless checkin
        checkin.activity = [] unless checkin.activity?.length > 0
        checkin.activity.push item._id
        Promise checkin.save()
        .then ->
          item.activityOf = checkin._id
          item
    else
      item

  events:
    activityItem:
      save:
        pre: preSave
