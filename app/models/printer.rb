class Printer < ActiveRecord::Base

  include ActiveUUID::UUID

  def self.find_by_id(id)
    find UUIDTools::UUID.parse(id)
  end

  belongs_to :print_queue
  attr_accessible :status

  # Connects with the 3d printer via the api and presents it as a model
  # TODO: printers with a current print job so that we can support more then 1 printer to a print queue

  def next_g_code_url
    job = print_queue.print_jobs.where("status != ? and status != ? and (copies_printed < copies_total)", :error, :printed).first
    raise "No jobs are ready to print" if job.blank?
    job.g_code.file.url
  end

  def start_printing
    job = print_queue.print_jobs.where("status != ? and status != ?", :error, :printed).first
    raise "No jobs are ready to print" if job.blank?
    job.status = :printing
    job.save!
  end

  def finish_printing(error = false)
    job = print_queue.print_jobs.where(:status => :printing).first
    # if no jobs were printing we were already finished printing so there is nothing to be done
    return if job.blank?

    job.copies_printed += 1
    job.status = error ? :printing_error : :printed if job.copies_printed >= job.copies_total
    job.save!
  end
end