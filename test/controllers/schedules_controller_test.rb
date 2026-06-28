# frozen_string_literal: true

require "test_helper"

class SchedulesControllerTest < ActionDispatch::IntegrationTest
  test "my schedule requires sign in" do
    get my_schedule_path
    assert_redirected_to root_path
  end

  test "shows meetups the user created and is attending" do
    # A meetup hosted by someone else that member RSVPs to.
    day = scheduling_days(:friday)
    host = User.create!(uid: 7002, login: "host", email: "h@example.com")
    others = Meetup.create!(
      event: events(:expo), user: host, location: locations(:main_stage),
      scheduling_day: day, starts_at: day.valid_start_times.find { |t| t.hour == 12 },
      title: "Others Party", description: "A meetup hosted by someone else.",
      status: :approved, tags: [ tags(:gaming) ]
    )
    Attendance.create!(user: users(:member), meetup: others)

    sign_in users(:member)
    get my_schedule_path
    assert_response :success
    assert_match "VTuber Fan Meetup", response.body # member created
    assert_match "Others Party", response.body       # member attending
  end

  test "excludes meetups the user neither created nor is attending" do
    day = scheduling_days(:friday)
    stranger = User.create!(uid: 7000, login: "stranger", email: "s@example.com")
    Meetup.create!(
      event: events(:expo), user: stranger, location: locations(:main_stage),
      scheduling_day: day, starts_at: day.valid_start_times.find { |t| t.hour == 12 },
      title: "Strangers Meetup", description: "A meetup by someone else entirely.",
      status: :approved, tags: [ tags(:gaming) ]
    )

    sign_in users(:member)
    get my_schedule_path
    assert_response :success
    assert_no_match "Strangers Meetup", response.body
  end

  test "filters my schedule by tag" do
    sign_in users(:member) # member hosts pending_vtuber + approved_cosplay (both cosplay)

    get my_schedule_path(tags: [ tags(:cosplay).public_id ])
    assert_response :success
    assert_match "VTuber Fan Meetup", response.body

    get my_schedule_path(tags: [ tags(:gaming).public_id ])
    assert_response :success
    assert_no_match "VTuber Fan Meetup", response.body
  end

  test "blank-slates a day the user has nothing on" do
    # A second event day with nothing on the user's schedule.
    events(:expo).scheduling_days.create!(date: scheduling_days(:friday).date + 1, start_time: "10:00", end_time: "17:00")
    sign_in users(:member) # member hosts meetups on the friday
    get my_schedule_path
    assert_response :success
    assert_match "Nothing scheduled for this day", response.body
  end

  test "shows the empty state when the user has nothing" do
    stranger = User.create!(uid: 7001, login: "lonely", email: "l@example.com")
    sign_in stranger
    get my_schedule_path
    assert_response :success
    assert_match "Nothing here yet", response.body
  end
end
