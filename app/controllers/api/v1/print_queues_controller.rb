class Api::V1::PrintQueuesController < ApplicationController
  inherit_resources

  respond_to :json

  def resource
    PrintQueue.find_by_printer_id(params[:print_queue_id])
  end

  def resource_class
    PrintQueue
  end

  # Returns the gcode for the next print job in the queue and updates it's status, increments the copies_printed
  def load_next_job
    printer = Printer.find_by_id(params[:print_queue_id])

    redirect_to printer.next_g_code_url
  end

  def start_printing
    printer = Printer.find_by_id(params[:print_queue_id])
    printer.start_printing
    render :nothing => true
  end

  def finish_printing
    printer = Printer.find_by_id(params[:print_queue_id])
    printer.finish_printing
    render :nothing => true
  end
end
