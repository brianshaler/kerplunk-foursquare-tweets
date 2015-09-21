_ = require 'lodash'
Promise = require 'when'

Filter = require '../src/index'

tweet1 =
  _id: 'tweet1'
  guid: '_test-tweet1'
  platform: 'twitter'
  message: 'no checkin'

tweet2 =
  _id: 'tweet2'
  guid: '_test-tweet2'
  platform: 'twitter'
  message: 'blah https://foursquare.com/wat/checkin/foursquare-id blah'

checkin1 =
  _id: 'checkin1'
  guid: '_test-checkin1'
  platform: 'foursquare'
  data:
    id: 'foursquare-id'

checkin2 =
  _id: 'checkin2'
  guid: '_test-checkin2'
  platform: 'foursquare'
  data:
    id: 'other-id'


FakeDocument = (obj, Model) ->
  doc = _.clone obj, true
  doc.save = ->
    Model._save doc._id, doc
    Promise()
  doc

FakeModel =
  data: []
  _save: (_id, doc) ->
    for item, index in @data
      if item._id == doc._id
        return @data[index] = doc
    return
  _get: (_id) ->
    for item, index in @data
      if item._id == _id
        return item
    return
  addData: (items) ->
    @data = items.map (obj) => FakeDocument obj, @
  where: (q) ->
    @q = q
    @
  findOne: ->
    Promise @data[0]
  find: ->
    Promise @data


describe 'index', ->

  before ->
    @System.registerModel 'ActivityItem', FakeModel
    @fsqtw = Filter(@System)

  beforeEach ->
    FakeModel.data = []

  it 'should not ignore tweets with no checkin url', (done) ->
    Promise @fsqtw.events.activityItem.save.pre tweet1
    .done (item) ->
      Should.exist item
      Should.not.exist item.activityOf
      Should.not.exist item.activity
      done()
    , (err) ->
      done err

  it 'should link a tweet with a matching data.link', (done) ->
    FakeModel.addData [checkin1]
    Promise @fsqtw.events.activityItem.save.pre tweet2
    .done (tweet) ->
      Should.exist tweet
      Should.not.exist tweet.activity
      Should.exist tweet.activityOf
      tweet.activityOf.should.equal checkin1._id
      checkin = FakeModel._get(checkin1._id)
      Should.exist checkin
      Should.exist checkin.activity
      checkin.activity[0].should.equal tweet2._id
      done()
    , (err) ->
      done err

  it 'should link a checkin with tweets containing a link to it', (done) ->
    FakeModel.addData [tweet2]
    Promise @fsqtw.events.activityItem.save.pre checkin1
    .done (checkin) ->
      Should.exist checkin
      Should.not.exist checkin.activityOf
      Should.exist checkin.activity
      checkin.activity[0].should.equal tweet2._id
      tweet = FakeModel._get(tweet2._id)
      Should.exist tweet
      Should.exist tweet.activityOf
      tweet.activityOf.should.equal checkin1._id
      done()
    , (err) ->
      done err
