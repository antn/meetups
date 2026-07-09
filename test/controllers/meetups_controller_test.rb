# frozen_string_literal: true

require "test_helper"

class MeetupsControllerTest < ActionDispatch::IntegrationTest
  # --- index: the schedule (home page) ---

  test "renders the schedule for the active event" do
    get root_path
    assert_response :success
    assert_match "Meetup schedule", response.body
    assert_match "Sep 12", response.body
  end

  test "approved meetups are public on the schedule" do
    get root_path
    assert_match "Cosplay Contest", response.body
  end

  test "another user's pending meetup shows only as a hold" do
    get root_path
    assert_match "Reserved", response.body
    assert_no_match "VTuber Fan Meetup", response.body
  end

  test "submitters see their own pending meetup on the schedule" do
    sign_in users(:member)
    get root_path
    assert_match "VTuber Fan Meetup", response.body
  end

  test "filters the schedule by tag" do
    # approved_cosplay carries the cosplay tag; nothing carries gaming.
    get root_path(tags: [ tags(:cosplay).public_id ])
    assert_response :success
    assert_match "Cosplay Contest", response.body

    get root_path(tags: [ tags(:gaming).public_id ])
    assert_response :success
    assert_no_match "Cosplay Contest", response.body
  end

  test "shows tag filter chips" do
    get root_path
    assert_match "Filter", response.body
    assert_match "Cosplay", response.body
    assert_match "Gaming", response.body
  end

  test "the day param selects that day's tab and filter links carry it" do
    expo = events(:expo)
    saturday = scheduling_days(:friday).date + 1
    expo.scheduling_days.create!(date: saturday, start_time: "10:00", end_time: "17:00")

    get root_path(day: saturday.iso8601)
    assert_response :success
    # The second day's tab is the selected one.
    selected = response.body[/aria-selected="true".*?<\/button>/m]
    assert_includes selected, saturday.strftime("%b %-d")
    # Filter chips preserve the day so a filter reload stays put.
    assert_match "day=#{saturday.iso8601}", response.body
  end

  test "the schedule badges meetups you host" do
    sign_in users(:member) # member hosts approved_cosplay
    get root_path
    assert_match "Your meetup", response.body
  end

  test "the schedule opens on today's tab when today is a meetup day" do
    expo = events(:expo)
    expo.scheduling_days.create!(date: expo.tz.today - 1, start_time: "10:00", end_time: "23:00") # yesterday
    expo.scheduling_days.create!(date: expo.tz.today, start_time: "10:00", end_time: "23:00")     # today

    get root_path
    assert_response :success
    # Exactly the today tab is pre-selected (not the earlier day or the fixture day).
    selected = response.body[/aria-selected="true".*?<\/button>/m]
    assert_includes selected, expo.tz.today.strftime("%b %-d")
  end

  test "open timeslots advertise remaining locations" do
    get root_path
    assert_match "location open", response.body
  end

  test "shows an empty state when no event is active" do
    events(:expo).update!(active: false)
    get root_path
    assert_response :success
    assert_match "No event scheduled", response.body
  end

  test "offers the create button when the event can accept meetups" do
    get root_path
    assert_match "Create a meetup", response.body
  end

  test "the create button opens the sign-in modal for signed-out visitors" do
    get root_path
    assert_select "sign-in-trigger button", text: /Create a meetup/
    assert_select "a[href='#{new_meetup_path}']", count: 0
  end

  test "the create button links to the form for signed-in users" do
    sign_in users(:member)
    get root_path
    assert_select "a[href='#{new_meetup_path}']", text: /Create a meetup/
  end

  test "hides the create button when the event has no bookable location" do
    locations(:main_stage).update!(active: false) # only an inactive location remains
    get root_path
    assert_response :success
    assert_no_match "Create a meetup", response.body
  end

  # --- show: a single meetup ---

  test "shows an approved meetup to anyone" do
    get meetup_path(meetups(:approved_cosplay).public_id)
    assert_response :success
    assert_match "Cosplay Contest", response.body
  end

  test "the show page's social card tags carry the day, time, and location" do
    get meetup_path(meetups(:approved_cosplay).public_id)
    expected = meetups(:approved_cosplay).social_description
    assert_select "meta[property='og:description'][content=?]", expected
    assert_select "meta[name='twitter:description'][content=?]", expected
    assert_select "meta[name='description'][content=?]", expected
  end

  test "an approved meetup shows the RSVP button to a signed-in non-host" do
    sign_in users(:guest)
    get meetup_path(meetups(:approved_cosplay).public_id)
    assert_match "I'm going!", response.body
  end

  test "shows Going for a viewer who already RSVP'd" do
    sign_in users(:admin) # admin attends approved_cosplay via fixture
    get meetup_path(meetups(:approved_cosplay).public_id)
    assert_match "Going", response.body
  end

  test "the host sees an attendee count instead of an RSVP button" do
    sign_in users(:member) # member hosts approved_cosplay; admin is attending it
    get meetup_path(meetups(:approved_cosplay).public_id)
    assert_match "1 person going", response.body
    assert_no_match "I'm going!", response.body
  end

  test "redirects away from another user's pending meetup" do
    get meetup_path(meetups(:pending_vtuber).public_id)
    assert_redirected_to root_path
  end

  test "lets the submitter view their own pending meetup" do
    sign_in users(:member)
    get meetup_path(meetups(:pending_vtuber).public_id)
    assert_response :success
    assert_match "VTuber Fan Meetup", response.body
    assert_match "awaiting admin approval", response.body
  end

  test "lets an admin view a pending meetup" do
    sign_in users(:admin)
    get meetup_path(meetups(:pending_vtuber).public_id)
    assert_response :success
    assert_match "VTuber Fan Meetup", response.body
  end

  test "redirects for an unknown meetup" do
    get meetup_path("doesnotexist")
    assert_redirected_to root_path
  end

  # --- new / create: requesting a meetup ---

  test "new requires sign in" do
    get new_meetup_path
    assert_redirected_to root_path
  end

  test "new renders the form for a signed-in user" do
    sign_in users(:member)
    get new_meetup_path
    assert_response :success
    assert_match "Request a meetup", response.body
    assert_match "Main Stage", response.body
  end

  test "new 404s when the event has no bookable location" do
    locations(:main_stage).update!(active: false)
    sign_in users(:member)
    get new_meetup_path
    assert_response :not_found
  end

  test "create 404s when the event has no bookable location" do
    locations(:main_stage).update!(active: false)
    sign_in users(:member)
    assert_no_difference -> { Meetup.count } do
      post meetups_path, params: { meetup: { title: "X" } }
    end
    assert_response :not_found
  end

  test "new preselects the slot passed from an open timeslot" do
    sign_in users(:member)
    get new_meetup_path(slot: free_slot_param(12))
    assert_response :success
    assert_match(/value="#{Regexp.escape(free_slot_param(12))}"[^>]*\bselected\b/, response.body)
  end

  test "creating a meetup requires sign in" do
    assert_no_difference -> { Meetup.count } do
      post meetups_path, params: { meetup: { title: "X" } }
    end
    assert_redirected_to root_path
  end

  test "creates a pending meetup in an open slot" do
    sign_in users(:member)
    assert_difference -> { Meetup.count }, 1 do
      post meetups_path, params: { meetup: {
        title: "Indie Game Night",
        description: "Bring your favorites.",
        location_id: locations(:main_stage).id,
        slot: free_slot_param(12),
        tag_ids: [ tags(:gaming).id ]
      } }
    end
    meetup = Meetup.order(:created_at).last
    assert_redirected_to meetup_path(meetup.public_id)
    assert_predicate meetup, :pending?
    assert_equal users(:member).id, meetup.user_id
    assert_equal [ tags(:gaming).id ], meetup.tag_ids
    assert_equal 12, meetup.starts_at.in_time_zone(events(:expo).tz).hour
  end

  test "rejects a booking on an already-taken slot" do
    sign_in users(:member)
    assert_no_difference -> { Meetup.count } do
      post meetups_path, params: { meetup: {
        title: "Clashing Meetup",
        description: "This should not be allowed to book.",
        location_id: locations(:main_stage).id,
        slot: taken_slot_param(10), # pending_vtuber already holds Main Stage @ 10am
        tag_ids: [ tags(:gaming).id ]
      } }
    end
    assert_response :unprocessable_entity
  end

  test "can't book a slot in the past" do
    past_day = events(:expo).scheduling_days.create!(date: Date.current - 1, start_time: "10:00", end_time: "17:00")
    sign_in users(:member)
    assert_no_difference -> { Meetup.count } do
      post meetups_path, params: { meetup: {
        title: "Too late",
        description: "Trying to book a slot that already passed.",
        location_id: locations(:main_stage).id,
        slot: "#{past_day.id}:#{past_day.valid_start_times.first.to_i}",
        tag_ids: [ tags(:gaming).id ]
      } }
    end
    assert_response :unprocessable_entity
    assert_match "has already passed", response.body
  end

  test "requires at least one tag" do
    sign_in users(:member)
    assert_no_difference -> { Meetup.count } do
      post meetups_path, params: { meetup: {
        title: "Tagless",
        description: "A meetup with no tags selected at all.",
        location_id: locations(:main_stage).id,
        slot: free_slot_param(13)
      } }
    end
    assert_response :unprocessable_entity
    assert_match "at least one tag", response.body
  end

  test "rejects a too-short description" do
    sign_in users(:member)
    assert_no_difference -> { Meetup.count } do
      post meetups_path, params: { meetup: {
        title: "Terse",
        description: "Too short",
        location_id: locations(:main_stage).id,
        slot: free_slot_param(13),
        tag_ids: [ tags(:gaming).id ]
      } }
    end
    assert_response :unprocessable_entity
    assert_match "Description is too short", response.body
  end

  # --- edit / update ---

  test "the submitter can open the edit form" do
    sign_in users(:member)
    get edit_meetup_path(meetups(:pending_vtuber).public_id)
    assert_response :success
    assert_match "Edit meetup", response.body
  end

  test "a non-owner, non-admin cannot edit someone else's meetup" do
    stranger = User.create!(uid: 9001, login: "stranger", email: "s@example.com")
    sign_in stranger
    get edit_meetup_path(meetups(:pending_vtuber).public_id)
    assert_redirected_to root_path
  end

  test "editing requires sign in" do
    get edit_meetup_path(meetups(:pending_vtuber).public_id)
    assert_redirected_to root_path
  end

  test "the submitter updates their meetup" do
    sign_in users(:member)
    patch meetup_path(meetups(:pending_vtuber).public_id), params: { meetup: {
      title: "Renamed VTuber Meetup",
      description: meetups(:pending_vtuber).description,
      location_id: meetups(:pending_vtuber).location_id,
      slot: "#{scheduling_days(:friday).id}:#{free_epoch(10)}",
      tag_ids: [ tags(:gaming).id ]
    } }
    meetup = meetups(:pending_vtuber).reload
    assert_redirected_to meetup_path(meetup.public_id)
    assert_equal "Renamed VTuber Meetup", meetup.title
    assert_equal [ tags(:gaming).id ], meetup.tag_ids
  end

  test "admins can edit another user's meetup" do
    sign_in users(:admin)
    get edit_meetup_path(meetups(:pending_vtuber).public_id)
    assert_response :success
  end

  # --- cancel ---

  test "the show page offers the host a cancel button with a confirmation" do
    sign_in users(:member)
    get meetup_path(meetups(:approved_cosplay).public_id)
    assert_select "form[action='#{cancel_meetup_path(meetups(:approved_cosplay).public_id)}'][data-turbo-confirm]"
  end

  test "the show page hides the cancel button from non-hosts" do
    sign_in users(:guest)
    get meetup_path(meetups(:approved_cosplay).public_id)
    assert_select "form[action='#{cancel_meetup_path(meetups(:approved_cosplay).public_id)}']", count: 0
  end

  test "the submitter cancels their meetup" do
    sign_in users(:member)
    patch cancel_meetup_path(meetups(:approved_cosplay).public_id)
    assert_redirected_to root_path
    assert meetups(:approved_cosplay).reload.cancelled?
  end

  test "cancelling requires sign in" do
    patch cancel_meetup_path(meetups(:approved_cosplay).public_id)
    assert_redirected_to root_path
    assert_not meetups(:approved_cosplay).reload.cancelled?
  end

  test "a non-owner, non-admin cannot cancel someone else's meetup" do
    sign_in users(:guest)
    patch cancel_meetup_path(meetups(:approved_cosplay).public_id)
    assert_redirected_to root_path
    assert_not meetups(:approved_cosplay).reload.cancelled?
  end

  test "admins can cancel another user's meetup" do
    sign_in users(:admin)
    patch cancel_meetup_path(meetups(:approved_cosplay).public_id)
    assert_redirected_to root_path
    assert meetups(:approved_cosplay).reload.cancelled?
  end

  test "an already-cancelled meetup can't be cancelled again" do
    meetups(:approved_cosplay).update!(status: :cancelled)
    sign_in users(:member)
    patch cancel_meetup_path(meetups(:approved_cosplay).public_id)
    assert_redirected_to root_path
    assert_equal "You can't cancel that meetup.", flash[:alert]
  end

  private

  def free_epoch(hour)
    scheduling_days(:friday).valid_start_times.find { |t| t.hour == hour }.to_i
  end

  def free_slot_param(hour)
    "#{scheduling_days(:friday).id}:#{free_epoch(hour)}"
  end
  alias taken_slot_param free_slot_param
end
