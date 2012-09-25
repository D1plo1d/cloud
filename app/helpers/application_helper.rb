module ApplicationHelper

  def breadcrumbs(queue, opts = {})
    opts = { :delimiter => " / ", :parent_links => true, :page_link => true }.merge opts
    b = ""

    # Owner
    b << link_to_if(opts[:parent_links], queue.owner, user_path(queue.owner), :class => "owner" ) do |t|
      "<span class='owner'>#{t}</span>".html_safe
    end
    # Deliminator
    b << opts[:delimiter]
    # This Page
    b << link_to_if(opts[:page_link], queue.to_s, user_print_queue_path(queue.owner, queue), :class => "print-queue" ) do |t|
      "<span class='print-queue'>#{t}</span>".html_safe
    end

    b.html_safe
  end

end
