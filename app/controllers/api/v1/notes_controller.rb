class Api::V1::NotesController < Api::V1::ApiController

  before_filter :get_course_role
  before_filter :get_note, only: [:update, :destroy]

  resource_description do
    api_versions "v1"
    short_description 'Represents a note added by the student on a course'
    description <<-EOS
      Stores text selection (notes) on a course’s content.  Notes are generated 
      by users as they highlight content, and then are fetched and re-stored when 
      the content is reloaded.
    EOS
  end

  api :GET, '/api/courses/:course_id/notes/:chapter.:section', 'Lists all user notes for the given course/page/section'
  description <<-EOS
    list all the notes added by the student to the given course, page and section
    `#{json_schema(Api::V1::NotesRepresenter, include: :readable)}`
  EOS
  def index
    respond_with Content::Models::Note.where(role: @role, page: page), represent_with: Api::V1::NotesRepresenter
  end

  ###############################################################
  # post
  ###############################################################
  api :POST, '/api/courses/:course_id/notes/:chapter.:section', 'Creates a Note'
  description <<-EOS
    Create a new note for the given course, chapter and section
    `#{json_schema(Api::V1::NoteRepresenter, include: :readable)}`
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


  api :PUT, '/api/courses/:course_id/notes/:chapter.:section/:id', 'Updates a Note'
  description <<-EOS
    Updates a note for the given course, chapter, section and id 
    `#{json_schema(Api::V1::NoteRepresenter, include: :readable)}`
  EOS
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

  api :DELETE, '/api/courses/:course_id/notes/:chapter.:section/:id', 'Deletes the note from the students course'
  description <<-EOS
    Deletes the note from the student's course with the provided :id
  EOS
  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_human_user, @note)
    @note.destroy!
    render_api_errors(@note.errors) || head(:ok)
  end

  api :GET, '/api/courses/:course_id/highlighted_sections', 'Lists a notes summary from the students course'
  description <<-EOS
    list all the notes added by the student to a course
    `#{json_schema(Api::V1::HighlightRepresenter, include: :readable)}`
  EOS
  def highlighted_sections
    # using @role as a substitute for a note in the `AccessPolicy`
    OSU::AccessPolicy.require_action_allowed!(:index, current_human_user, @role)
    
    page_ids = Content::Models::Note.where(role: @role).group(:content_page_id).pluck(:content_page_id)
    pages = Content::Models::Page.where(id: page_ids)
    respond_with pages, represent_with: Api::V1::HighlightRepresenter  
  end

  protected

  def get_note
    @note = Content::Models::Note.find_by!(
      id: params[:id], role: @role
    )
  end

  def get_course_role
    @course = CourseProfile::Models::Course.find(params[:course_id])
    @role = ChooseCourseRole.call(user: current_human_user, course: @course).outputs.role
  end

  def page
    @page ||= @course.ecosystem.pages.book_location(params[:chapter], params[:section]).first
  end


end
