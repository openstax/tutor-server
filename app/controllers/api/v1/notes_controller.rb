class Api::V1::NotesController < Api::V1::ApiController

  before_filter :get_course_role
  before_filter :get_note, only: [:update, :destroy]

  def index
    respond_with Content::Models::Note.where(role: @role, page: page), represent_with: Api::V1::NotesRepresenter
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
    note = Content::Models::Note.new(role: @role, content_page_id: params[:page_id])
    consume!(note, represent_with: Api::V1::NoteRepresenter)
    OSU::AccessPolicy.require_action_allowed!(:create, current_human_user, note)
    note.page = page
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

  def highlighted_sections
    #pages = Content::Models::Note.where(role: @role).group(:content_page_id).select(:content_page_id)
    
    page_ids = Content::Models::Note.where(role: @role).group(:content_page_id).pluck(:content_page_id)
    pages = Content::Models::Page.where(id: page_ids)
    
    respond_with(OpenStruct.new({ pages: pages }), represent_with: Api::V1::HighlightRepresenter)

  
  end

  protected

  def get_note
    @note = Content::Models::Note.find_by!(
      id: params[:id], role: @role
    )
  end

  def get_course_role
    @course = CourseProfile::Models::Course.find(params[:course_id])
    @role = ChooseCourseRole[user: current_human_user, course: @course]
  end

  def page
    @page ||= @course.ecosystem.pages.book_location(params[:chapter], params[:section]).first
  end


end
