require 'java'
require File.join(File.dirname(__FILE__), '..', 'lib', 'swt')
require File.join(File.dirname(__FILE__), '..', 'lib', 'downloader')

# This code is based on 
#
# http://www.java2s.com/Code/Java/SWT-JFace-Eclipse/DemonstratestheDirectoryDialogclass.htm
#   for the usage of the DirectoryDialog
#
# http://www.rubyinside.com/jruby-swt-future-cross-platform-ruby-desktop-app-development-298.html#comment-1466
#   for the rubyfication of the SWT library calls
# 
# http://github.com/danlucraft/jruby-swt-cookbook/
#   for proper click handler creation

class ShowDirectoryDialog
  Button           = org.eclipse.swt.widgets.Button
  DirectoryDialog  = org.eclipse.swt.widgets.DirectoryDialog
  Display          = org.eclipse.swt.widgets.Display
  GridData         = org.eclipse.swt.layout.GridData
  GridLayout       = org.eclipse.swt.layout.GridLayout
  Label            = org.eclipse.swt.widgets.Label
  ProgressBar      = org.eclipse.swt.widgets.ProgressBar
  SelectionAdapter = org.eclipse.swt.events.SelectionAdapter
  Shell            = org.eclipse.swt.widgets.Shell
  SWT              = org.eclipse.swt.SWT
  Text             = org.eclipse.swt.widgets.Text

  # Runs the application
  def initialize
    Display.app_name = 'Flickr Downloader'
    display = Display.get_current

    @shell = Shell.new display
    @shell.text = "Flickr Downloader"

    create_contents

    @shell.pack
    @shell.open

  end

  def run
    display = Display.get_current
    while !@shell.disposed? do
      display.sleep unless !display.read_and_dispatch
    end
  end

  # Creates the window contents
  def create_contents
    @shell.layout = GridLayout.new(6, true)

    Label.new(@shell, SWT::NONE).text = "Shared link:"

    @url_box = Text.new(@shell, SWT::BORDER)
    layout_data = GridData.new(GridData::FILL_HORIZONTAL)
    layout_data.horizontalSpan = 4
    @url_box.layout_data = layout_data

    # spacer - this should work in a different way, I guess
    Label.new(@shell, SWT::NONE)

    Label.new(@shell, SWT::NONE).text = "Directory:"

    # Create the text box extra wide to show long paths
    @dir_box = Text.new(@shell, SWT::BORDER)
    layout_data = GridData.new(GridData::FILL_HORIZONTAL)
    layout_data.horizontalSpan = 4
    @dir_box.layout_data = layout_data 

    # Clicking the button will allow the user to select a directory
    @dir_button = Button.new(@shell, SWT::PUSH)

    @dir_button.text = "Browse..."
    @dir_button.addSelectionListener do
      handle_open_dialog
    end

    @progress_bar = ProgressBar.new(@shell, SWT::SMOOTH)
    layout_data = GridData.new(GridData::FILL_HORIZONTAL)
    layout_data.horizontalSpan = 6
    @progress_bar.layout_data = layout_data 


		@start_button = Button.new(@shell, SWT::PUSH)
		@start_button.text = "Start downloading"
		layout_data = GridData.new(GridData::END, GridData::CENTER, false, false)
		layout_data.horizontalSpan = 6
		@start_button.layout_data = layout_data
    @start_button.addSelectionListener do
      handle_start_download
    end
  end

  def disable_controls
    @dir_button.enabled = false
    @dir_box.enabled = false
    @url_box.enabled = false
    @start_button.enabled = false
  end

  def enable_controls
    @dir_button.enabled = true
    @dir_box.enabled = true
    @url_box.enabled = true
    @start_button.enabled = true
  end

  def handle_start_download
    folder = @dir_box.text.strip
    url = @url_box.text.strip

    unless folder.empty? || url.empty?
      disable_controls
      @progress_bar.set_selection 0
      display = Display.get_current

      Thread.new do
        begin
          downloader = Downloader.new(:folder => folder, :url => url)

          downloader.on_photo_saved do |photo, index|
            display.sync_exec do
              #
              #      photo.size         index + 1
              # -------------------  =  ---------
              # progess_bar.maximum       ???
              @progress_bar.set_selection(
                @progress_bar.maximum * (index + 1) / downloader.photos.size
              )
            end
          end

          downloader.download

          print "\n"

          display.sync_exec do
            @progress_bar.set_selection @progress_bar.maximum
            enable_controls
          end
        rescue
          puts $!
          puts $@
        end
      end
    end
  end

  def handle_open_dialog
    dlg = DirectoryDialog.new(@shell)

    # Set the initial filter path according
    # to anything they've selected or typed in
    dlg.filter_path = @dir_box.text

    # Change the title bar text
    dlg.text = "Choose download folder for images"

    # Customizable message displayed in the dialog
    dlg.message = "Select a directory"

    # Calling open() will open and run the dialog.
    # It will return the selected directory, or
    # nil if user cancels
    dir = dlg.open

    unless dir.nil?
      # Set the text box to the new selection
      @dir_box.text = dir
    end
  end
end

ShowDirectoryDialog.new.run
