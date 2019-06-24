# coding: utf-8
class Api::V1::NotesController < Api::V1::ApiController

  before_action :get_course, except: [ :update, :destroy ]
  before_action :choose_course_role, only: [:create, :highlighted_sections]
  before_action :get_note, only: [ :update, :destroy ]

  resource_description do
    api_versions "v1"
    short_description 'Represents a note added by the student on a course'
    description <<-EOS
      Stores text selection (notes) on a course’s content.
      Notes are generated by users as they highlight content,
      and then are fetched and re-stored when the content is reloaded.
    EOS
  end

  ####################################################################
  ## index                                                          ##
  ####################################################################
  api :GET, '/api/courses/:course_id/notes/:chapter.:section', 'Lists all notes'
  description <<-EOS
    Lists all the notes added by the student to the given course, page and section

    #{json_schema(Api::V1::NotesRepresenter, include: :readable)}
  EOS
  def index
    roles = current_human_user.roles
    page_uuid = @course.ecosystem.pages.book_location(params[:chapter], params[:section])
      .pluck(:uuid)
      .first || raise(ActiveRecord::RecordNotFound)

    notes = Content::Models::Note.joins(:page).where(role: roles, page: { uuid: page_uuid })
    respond_with notes, represent_with: Api::V1::NotesRepresenter
  end

  ####################################################################
  ## create                                                         ##
  ####################################################################
  api :POST, '/api/courses/:course_id/notes/:chapter.:section(/role/:role_id)', 'Creates a note'
  description <<-EOS
    Creates a new note for the given course, chapter and section

    #{json_schema(Api::V1::NoteRepresenter, include: :readable)}
  EOS
  def create
    note = Content::Models::Note.new(role: @role, content_page_id: params[:page_id])
    consume!(note, represent_with: Api::V1::NoteRepresenter)
    OSU::AccessPolicy.require_action_allowed!(:create, current_api_user, note)
    note.page = @course.ecosystem.pages.book_location(params[:chapter], params[:section]).first!
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
  api :PUT, '/api/courses/:course_id/notes/:chapter.:section/:id', 'Updates a note'
  description <<-EOS
    Updates the note with the given id

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
  ## destroy                                                        ##
  ####################################################################
  api :DELETE, '/api/courses/:course_id/notes/:chapter.:section/:id', 'Deletes a note'
  description <<-EOS
    Deletes the note with the given id
  EOS
  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_api_user, @note)
    @note.destroy
    render_api_errors(@note.errors) || head(:ok)
  end

  ####################################################################
  ## highlighted_sections                                           ##
  ####################################################################
  api :GET, '/api/courses/:course_id/highlighted_sections',
            'Shows a summary of sections highlighted by the student'
  description <<-EOS
    List all sections highlighted by the student

    #{json_schema(Api::V1::HighlightRepresenter, include: :readable)}
  EOS

  def highlighted_sections
    pages = Content::Models::Page.select(:id, :title, :book_location, 'count(*) as notes_count')
                                 .joins(:notes)
                                 .where(notes: { role: @role })
                                 .group(:id)
    respond_with pages, represent_with: Api::V1::HighlightRepresenter
  end

  protected

  def get_course
    @course = CourseProfile::Models::Course.find(params[:course_id])
  end

  def choose_course_role
    result = ChooseCourseRole.call(
      user: current_human_user, course: @course, role_id: params[:role_id]
    )
    raise(SecurityTransgression, :invalid_role) unless result.errors.empty?

    @role = result.outputs.role
  end

  def get_note
    @note = Content::Models::Note.find(params[:id])
  end

end
