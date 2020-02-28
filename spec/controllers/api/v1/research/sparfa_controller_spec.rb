require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::Research::SparfaController, type: :controller,
                                                    api: true,
                                                    version: :v1,
                                                    speed: :slow do
  let(:task_plan)        { FactoryBot.create :tasked_task_plan, number_of_students: 2 }
  let(:course_1)         { task_plan.owner }
  let(:period)           { task_plan.tasking_plans.first.target }
  let(:student)          { period.students.to_a.first }
  let!(:teacher_student) { FactoryBot.create :course_membership_teacher_student, period: period }

  let!(:course_2)        { FactoryBot.create :course_profile_course }

  let(:research_user)    { FactoryBot.create :user_profile, :researcher }
  let(:research_token)   do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: research_user.id
  end

  before                 { DistributeTasks.call task_plan: task_plan }

  context 'GET #students' do
    let(:params) { { research_identifiers: [ student.research_identifier ] } }

    it 'retrieves exercises and matrices for students with the given research_identifiers' do
      api_post :students, research_token, body: params.to_json

      expect(response).to be_ok
      expect(response.body_as_hash).to match(
        [
          a_hash_including(
            ordered_exercise_numbers: kind_of(Array),
            ecosystem_matrix: {
              responded_before: kind_of(String),
              research_identifiers: [ student.research_identifier ],
              exercise_uids: kind_of(Array),
              L_ids: [ student.uuid ],
              Q_ids: kind_of(Array),
              C_ids: kind_of(Array),
              d_data: kind_of(Array),
              W_data: kind_of(Array),
              W_row: kind_of(Array),
              W_col: kind_of(Array),
              H_mask_data: kind_of(Array),
              H_mask_row: kind_of(Array),
              H_mask_col: kind_of(Array),
              G_data: kind_of(Array),
              G_row: kind_of(Array),
              G_col: kind_of(Array),
              G_mask_data: kind_of(Array),
              G_mask_row: kind_of(Array),
              G_mask_col: kind_of(Array),
              U_data: kind_of(Array),
              U_row: kind_of(Array),
              U_col: kind_of(Array),
              superseded_at: kind_of(String)
            }
          )
        ]
      )
    end
  end

  context 'GET #task_plans' do
    let(:task_plan_ids) { [ task_plan.id ] }

    context 'without research_identifiers' do
      let(:params) { { task_plan_ids: task_plan_ids } }

      context 'without calculation uuids' do
        it 'retrieves exercises and ecosystem matrices for task_plans with the given ids' do
          api_post :task_plans, research_token, body: params.to_json

          expect(response).to be_ok
          expect(response.body_as_hash).to match(
            [
              a_hash_including(
                students: a_collection_containing_exactly(
                  *period.students.map do |student|
                    a_hash_including(
                      active: {
                        ordered_exercise_numbers: kind_of(Array),
                        ecosystem_matrix: {
                          responded_before: kind_of(String),
                          research_identifiers: [ student.research_identifier ],
                          exercise_uids: kind_of(Array),
                          L_ids: [ student.uuid ],
                          Q_ids: kind_of(Array),
                          C_ids: kind_of(Array),
                          d_data: kind_of(Array),
                          W_data: kind_of(Array),
                          W_row: kind_of(Array),
                          W_col: kind_of(Array),
                          H_mask_data: kind_of(Array),
                          H_mask_row: kind_of(Array),
                          H_mask_col: kind_of(Array),
                          G_data: kind_of(Array),
                          G_row: kind_of(Array),
                          G_col: kind_of(Array),
                          G_mask_data: kind_of(Array),
                          G_mask_row: kind_of(Array),
                          G_mask_col: kind_of(Array),
                          U_data: kind_of(Array),
                          U_row: kind_of(Array),
                          U_col: kind_of(Array),
                          superseded_at: kind_of(String)
                        }
                      }
                    )
                  end
                )
              )
            ]
          )
        end
      end

      context 'with calculation uuids' do
        before do
          task_plan.tasks.each do |task|
            task.pe_calculation_uuid = SecureRandom.uuid
            task.spe_calculation_uuid = SecureRandom.uuid
            task.save!
          end
        end

        it 'retrieves exercises and ecosystem matrices for task_plans with the given ids' do
          api_post :task_plans, research_token, body: params.to_json

          expect(response).to be_ok
          expect(response.body_as_hash).to match(
            [
              a_hash_including(
                students: a_collection_containing_exactly(
                  *period.students.map do |student|
                    a_hash_including(
                      pes: {
                        ordered_exercise_numbers: kind_of(Array),
                        ecosystem_matrix: {
                          responded_before: kind_of(String),
                          research_identifiers: [ student.research_identifier ],
                          exercise_uids: kind_of(Array),
                          L_ids: [ student.uuid ],
                          Q_ids: kind_of(Array),
                          C_ids: kind_of(Array),
                          d_data: kind_of(Array),
                          W_data: kind_of(Array),
                          W_row: kind_of(Array),
                          W_col: kind_of(Array),
                          H_mask_data: kind_of(Array),
                          H_mask_row: kind_of(Array),
                          H_mask_col: kind_of(Array),
                          G_data: kind_of(Array),
                          G_row: kind_of(Array),
                          G_col: kind_of(Array),
                          G_mask_data: kind_of(Array),
                          G_mask_row: kind_of(Array),
                          G_mask_col: kind_of(Array),
                          U_data: kind_of(Array),
                          U_row: kind_of(Array),
                          U_col: kind_of(Array),
                          superseded_at: kind_of(String)
                        }
                      },
                      spes: {
                        ordered_exercise_numbers: kind_of(Array),
                        ecosystem_matrix: {
                          responded_before: kind_of(String),
                          research_identifiers: [ student.research_identifier ],
                          exercise_uids: kind_of(Array),
                          L_ids: [ student.uuid ],
                          Q_ids: kind_of(Array),
                          C_ids: kind_of(Array),
                          d_data: kind_of(Array),
                          W_data: kind_of(Array),
                          W_row: kind_of(Array),
                          W_col: kind_of(Array),
                          H_mask_data: kind_of(Array),
                          H_mask_row: kind_of(Array),
                          H_mask_col: kind_of(Array),
                          G_data: kind_of(Array),
                          G_row: kind_of(Array),
                          G_col: kind_of(Array),
                          G_mask_data: kind_of(Array),
                          G_mask_row: kind_of(Array),
                          G_mask_col: kind_of(Array),
                          U_data: kind_of(Array),
                          U_row: kind_of(Array),
                          U_col: kind_of(Array),
                          superseded_at: kind_of(String)
                        }
                      }
                    )
                  end
                )
              )
            ]
          )
        end
      end
    end

    context 'with research_identifiers' do
      let(:params) do
        { task_plan_ids: task_plan_ids, research_identifiers: [ student.research_identifier ] }
      end

      context 'without calculation uuids' do
        it 'retrieves exercises and ecosystem matrices for task_plans with the given ids' do
          api_post :task_plans, research_token, body: params.to_json

          expect(response).to be_ok
          expect(response.body_as_hash).to match(
            [
              a_hash_including(
                students: [
                  a_hash_including(
                    active: {
                      ordered_exercise_numbers: kind_of(Array),
                      ecosystem_matrix: {
                        responded_before: kind_of(String),
                        research_identifiers: [ student.research_identifier ],
                        exercise_uids: kind_of(Array),
                        L_ids: [ student.uuid ],
                        Q_ids: kind_of(Array),
                        C_ids: kind_of(Array),
                        d_data: kind_of(Array),
                        W_data: kind_of(Array),
                        W_row: kind_of(Array),
                        W_col: kind_of(Array),
                        H_mask_data: kind_of(Array),
                        H_mask_row: kind_of(Array),
                        H_mask_col: kind_of(Array),
                        G_data: kind_of(Array),
                        G_row: kind_of(Array),
                        G_col: kind_of(Array),
                        G_mask_data: kind_of(Array),
                        G_mask_row: kind_of(Array),
                        G_mask_col: kind_of(Array),
                        U_data: kind_of(Array),
                        U_row: kind_of(Array),
                        U_col: kind_of(Array),
                        superseded_at: kind_of(String)
                      }
                    }
                  )
                ]
              )
            ]
          )
        end
      end

      context 'with calculation uuids' do
        before do
          task_plan.tasks.each do |task|
            task.pe_calculation_uuid = SecureRandom.uuid
            task.spe_calculation_uuid = SecureRandom.uuid
            task.save!
          end
        end

        it 'retrieves exercises and ecosystem matrices for task_plans with the given ids' do
          api_post :task_plans, research_token, body: params.to_json

          expect(response).to be_ok
          expect(response.body_as_hash).to match(
            [
              a_hash_including(
                students: [
                  a_hash_including(
                    pes: {
                      ordered_exercise_numbers: kind_of(Array),
                      ecosystem_matrix: {
                        responded_before: kind_of(String),
                        research_identifiers: [ student.research_identifier ],
                        exercise_uids: kind_of(Array),
                        L_ids: [ student.uuid ],
                        Q_ids: kind_of(Array),
                        C_ids: kind_of(Array),
                        d_data: kind_of(Array),
                        W_data: kind_of(Array),
                        W_row: kind_of(Array),
                        W_col: kind_of(Array),
                        H_mask_data: kind_of(Array),
                        H_mask_row: kind_of(Array),
                        H_mask_col: kind_of(Array),
                        G_data: kind_of(Array),
                        G_row: kind_of(Array),
                        G_col: kind_of(Array),
                        G_mask_data: kind_of(Array),
                        G_mask_row: kind_of(Array),
                        G_mask_col: kind_of(Array),
                        U_data: kind_of(Array),
                        U_row: kind_of(Array),
                        U_col: kind_of(Array),
                        superseded_at: kind_of(String)
                      }
                    },
                    spes: {
                      ordered_exercise_numbers: kind_of(Array),
                      ecosystem_matrix: {
                        responded_before: kind_of(String),
                        research_identifiers: [ student.research_identifier ],
                        exercise_uids: kind_of(Array),
                        L_ids: [ student.uuid ],
                        Q_ids: kind_of(Array),
                        C_ids: kind_of(Array),
                        d_data: kind_of(Array),
                        W_data: kind_of(Array),
                        W_row: kind_of(Array),
                        W_col: kind_of(Array),
                        H_mask_data: kind_of(Array),
                        H_mask_row: kind_of(Array),
                        H_mask_col: kind_of(Array),
                        G_data: kind_of(Array),
                        G_row: kind_of(Array),
                        G_col: kind_of(Array),
                        G_mask_data: kind_of(Array),
                        G_mask_row: kind_of(Array),
                        G_mask_col: kind_of(Array),
                        U_data: kind_of(Array),
                        U_row: kind_of(Array),
                        U_col: kind_of(Array),
                        superseded_at: kind_of(String)
                      }
                    }
                  )
                ]
              )
            ]
          )
        end
      end
    end
  end
end
