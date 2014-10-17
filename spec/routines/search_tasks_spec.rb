require 'rails_helper'

describe SearchTasks do

  let!(:task_1) { FactoryGirl.create(:assigned_task).task.reload }

  let!(:task_2) { FactoryGirl.create(:assigned_task).task.reload }

  let!(:task_3) { FactoryGirl.create(:assigned_task).task.reload }

  before(:each) do
    100.times do
      FactoryGirl.create(:task)
    end
  end

  it 'filters results based on task id' do
    items = SearchTasks.call(params: {
              q: "id:#{task_1.id}"}).outputs[:items]

    expect(items).to include(task_1)
    expect(items).not_to include(task_2)
    expect(items).not_to include(task_3)

    items = SearchTasks.call(params: {
              q: "id:#{task_2.id},#{task_3.id}"}).outputs[:items]

    expect(items).not_to include(task_1)
    expect(items).to include(task_2)
    expect(items).to include(task_3)
  end

  it 'filters results based on user_id' do
    items = SearchTasks.call(params: {
              q: "user_id:#{task_1.assigned_tasks.first.user_id}"}).outputs[:items]

    expect(items).to include(task_1)
    expect(items).not_to include(task_2)
    expect(items).not_to include(task_3)

    items = SearchTasks.call(params: {
              q: "user_id:#{task_2.assigned_tasks.first.user_id},#{
                 task_3.assigned_tasks.first.user_id}"}).outputs[:items]

    expect(items).not_to include(task_1)
    expect(items).to include(task_2)
    expect(items).to include(task_3)
  end

  it 'filters results based on both fields' do
    items = SearchTasks.call(params: {
              q: "id:#{task_1.id},#{task_2.id} user_id:#{
                   task_2.assigned_tasks.first.user_id},#{
                   task_3.assigned_tasks.first.user_id}"}).outputs[:items]

    expect(items).not_to include(task_1)
    expect(items).to include(task_2)
    expect(items).not_to include(task_3)
  end

  it "orders results" do
    items = SearchTasks.call(params: {
                order_by: 'cReAtEd_At AsC, iD',
                q: ''}).outputs[:items].to_a
    expect(items).to include(task_1)
    expect(items).to include(task_2)
    expect(items).to include(task_3)
    task_1_index = items.index(task_1)
    task_2_index = items.index(task_2)
    task_3_index = items.index(task_3)
    expect(task_2_index).to be > task_1_index
    expect(task_3_index).to be > task_2_index

    items = SearchTasks.call(params: {
              order_by: 'CrEaTeD_aT dEsC, Id DeSc',
              q: 'username:dOe'}).outputs[:items].to_a
    expect(items).to include(task_1)
    expect(items).to include(task_2)
    expect(items).to include(task_3)
    task_1_index = items.index(task_1)
    task_2_index = items.index(task_2)
    task_3_index = items.index(task_3)
    expect(task_2_index).to be < task_1_index
    expect(task_3_index).to be < task_2_index
  end

  it "paginates results" do
    all_items = Task.all.to_a

    items = SearchTasks.call(params: {q: '',
                             per_page: 20}).outputs[:items]
    expect(items.limit(nil).offset(nil).count).to eq all_items.length
    expect(items.limit(nil).offset(nil).to_a).to eq all_items
    expect(items.count).to eq 20
    expect(items.to_a).to eq all_items[0..19]

    for page in 1..5
      items = SearchTasks.call(params: {q: '',
                               per_page: 20,
                               page: page}).outputs[:items]
      expect(items.limit(nil).offset(nil).count).to eq all_items.count
      expect(items.limit(nil).offset(nil).to_a).to eq all_items
      expect(items.count).to eq 20
      expect(items.to_a).to eq all_items.slice(20*(page-1), 20)
    end

    items = SearchTasks.call(params: {q: '',
                             per_page: 20,
                             page: 1000}).outputs[:items]
    expect(items.limit(nil).offset(nil).count).to eq all_items.count
    expect(items.limit(nil).offset(nil).to_a).to eq all_items
    expect(items.count).to eq 0
    expect(items.to_a).to be_empty
  end

end
