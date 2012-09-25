require_relative "push_controller.rb"

class PrintJobsPushController < PushController

  def initialize(print_job)
    @print_job = print_job
  end


  def update()
    #publish :method => :update, :row_html => render(:partial => @print_job, :locals => {:print_job_format => :row})
    publish :method => :update
  end

  def destroy()
    publish :method => :destroy
  end


  protected

    def publish(opts)
      PrivatePub.publish_to channel, { :print_job => @print_job.as_row }.merge(opts)
    end

    def channel()
      @print_job.print_queue.pub_sub_channel
    end

end