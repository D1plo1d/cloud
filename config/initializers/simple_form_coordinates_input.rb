class CoordinatesInput < SimpleForm::Inputs::Base
  def input
    join = "<span class='coordinates-join'> x </span>"
    [0,1].map {|i| @builder.text_field options[:field_names_method].call(i), input_html_options }.join(join).html_safe
  end
end