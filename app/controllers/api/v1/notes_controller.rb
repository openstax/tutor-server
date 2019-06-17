# coding: utf-8
class Api::V1::NotesController < Api::V1::ApiController

  before_action :get_course_role
  before_action :get_note, only: [:update, :destroy]

  resource_description do
    api_versions "v1"
    short_description 'Represents a note added by the student on a course'
    description <<-EOS
      Stores text selection (notes) on a course’s content.  Notes are generated
      by users as they highlight content, and then are fetched and re-stored when
      the content is reloaded.
    EOS
  end

  ####################################################################
  ## index                                                          ##
  ####################################################################
  api :GET, '/api/courses/:course_id/notes/:chapter.:section', 'Lists all user notes for the given course/page/section'
  description <<-EOS
    list all the notes added by the student to the given course, page and section
    #{json_schema(Api::V1::NotesRepresenter, include: :readable)}
  EOS
  def index
    page_ids = Content::Models::Page
               .joins(:notes)
               .where(notes: { role: @role })
               .book_location(params[:chapter], params[:section])
               .pluck(:id)
    notes = Content::Models::Note.where(role: @role, content_page_id: page_ids)
    respond_with notes, represent_with: Api::V1::NotesRepresenter
  end

  ###############################################################
  # post
  ###############################################################
  api :POST, '/api/courses/:course_id/notes/:chapter.:section', 'Creates a Note'
  description <<-EOS
    Create a new note for the given course, chapter and section
    #{json_schema(Api::V1::NoteRepresenter, include: :readable)}
  EOS
  def create
    note = Content::Models::Note.new(role: @role, content_page_id: params[:page_id])
    consume!(note, represent_with: Api::V1::NoteRepresenter)
    OSU::AccessPolicy.require_action_allowed!(:create, current_api_user, note)
    note.page = @course.ecosystem.pages.book_location(
      params[:chapter], params[:section],
    ).first!
    if note.save
      respond_with note, responder: ResponderWithPutPatchDeleteContent,
                   represent_with: Api::V1::NoteRepresenter,
                   location: nil
    else
      render_api_errors(note.errors)
    end
  end

  ####################################################################
  ## update                                                         ##
  ####################################################################
  api :PUT, '/api/courses/:course_id/notes/:chapter.:section/:id', 'Updates a Note'
  description <<-EOS
    Updates a note for the given course, chapter, section and id
    #{json_schema(Api::V1::NoteRepresenter, include: :readable)}
  EOS
  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, @note)
    consume!(@note, represent_with: Api::V1::NoteRepresenter)
    @note.save
    render_api_errors(@note.errors) || respond_with(
      @note,
      responder: ResponderWithPutPatchDeleteContent,
      represent_with: Api::V1::NoteRepresenter,
      location: nil
    )
  end

  ####################################################################
  ## delete                                                         ##
  ####################################################################
  api :DELETE, '/api/courses/:course_id/notes/:chapter.:section/:id', 'Deletes the note from the students course'
  description <<-EOS
    Deletes the note from the student's course with the provided :id
  EOS
  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_api_user, @note)
    @note.destroy!
    render_api_errors(@note.errors) || head(:ok)
  end

  api :GET, '/api/courses/:course_id/highlighted_sections', 'Lists a notes summary from the students course'
  description <<-EOS
    list all the notes added by the student to a course
    #{json_schema(Api::V1::HighlightRepresenter, include: :readable)}
  EOS
  def highlighted_sections
    pages = Content::Models::Page
              .select('content_pages.id, content_pages.title, content_pages.book_location, count(*) as notes_count')
              .group(:id)
              .joins(:notes)
              .where(notes: { role: @role })
    respond_with pages, represent_with: Api::V1::HighlightRepresenter
  end

  protected

  def get_note
    @note = Content::Models::Note.find_by(
      id: params[:id], role: @role
    )
  end

  def get_course_role
    @course = CourseProfile::Models::Course.find(params[:course_id])

    result = ChooseCourseRole.call(
      user: current_human_user, course: @course, role_id: params[:role_id]
    )
    errors = result.errors
    raise(SecurityTransgression, :invalid_role) unless errors.empty?

    @role = result.outputs.role
  end

end
