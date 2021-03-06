class HeadshotController < ApplicationController
  include HeadshotSupport
  def capture
    file_path = ''
    begin
      file_path = method(:headshot_custom_file_path).call
    rescue
      file_path = headshot_file_path
    end

    # Pre save hook.
    begin
      method(:headshot_pre_save).call(file_path)
    rescue
      # No pre save hook.
    end

    # Method for saving the JPEG file.
    begin
      method(:headshot_custom_save_image).call(file_path, request.raw_post)

    # Only catch the error if method is undefined.
    rescue NameError => e
      saving_result = headshot_save_image(file_path, request.raw_post)

      unless saving_result
        render :json => {
          :status => 'Error',
          :message => 'Saving of headshot failed.'
        }
        return
      end
    end

    # Post save hook.
    begin
      method(:headshot_post_save).call(headshot_params)
    rescue
      @headshot_photo = HeadshotPhoto.create(headshot_params)
    end

    headshot_url = ""
    begin
      headshot_url = method(:headshot_custom_image_url).call(File.basename(file_path))
    rescue
      headshot_url = "#{headshot_image_url(File.basename(file_path))}"
    end

    begin
      method(:headshot_user_save).call(headshot_params)
    rescue
    end

    render :json => {
      :status => 'Success',
      :message => 'Headshot saved.',
      :url => headshot_url
    }
  end



  def headshot_params
    params.require(:headshot_photo).permit(:description,
                                     :image_file_size,
                                     :image_file_name => File.basename(file_path),
                                     :image_content_type => 'image/jpeg',
                                     :image_updated_at => Time.now)
  end

end
