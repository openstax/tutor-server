class Api::V1::NotesController < Api::V1::ApiController

  before_filter :get_course_role
  before_filter :get_note, only: [:update, :destroy]

  def index
    respond_with Notes::Models::Note.where(
                   role: @role, content_page_id: params[:page_id]
                 ), represent_with: Api::V1::NotesRepresenter
  end

  ###############################################################
  # post
  ###############################################################
  api :POST, '/notes/:course_id/notes/:page_id', 'Creates a Note'
  description <<-EOS
  Create a new note for the given page and role, and page element referenced by
  the anchor
  EOS
  def create
    note = Notes::Models::Note.new(role: @role, content_page_id: params[:page_id])
    consume!(note, represent_with: Api::V1::NoteRepresenter)
    OSU::AccessPolicy.require_action_allowed!(:create, current_human_user, note)

    if note.save
      respond_with note, responder: ResponderWithPutPatchDeleteContent,
                   represent_with: Api::V1::NoteRepresenter,
                   location: nil
    else
      render_api_errors(note.errors)
    end
  end

  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_human_user, @note)
    consume!(@note, represent_with: Api::V1::NoteRepresenter)
    @note.save
    render_api_errors(@note.errors) || respond_with(
      @note,
      responder: ResponderWithPutPatchDeleteContent,
      represent_with: Api::V1::NoteRepresenter,
      location: nil
    )
  end

  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_human_user, @note)
    @note.destroy!
    render_api_errors(@note.errors) || head(:ok)
  end

  protected

  def get_note
    @note = Notes::Models::Note.find_by!(
      id: params[:id], role: @role
    )
  end

  def get_course_role
    @course = CourseProfile::Models::Course.find(params[:course_id])
    @role = ChooseCourseRole[user: current_human_user, course: @course]
  end

end
