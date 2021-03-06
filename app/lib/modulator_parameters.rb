#
# metaflop - web interface
# © 2012 by alexis reigel
# www.metaflop.com
#
# licensed under gpl v3
#

class ModulatorParameters
  def initialize(font_parameters)
    @font_parameters = font_parameters
  end

  def default_parameters
    [{
      title: 'Dimension',
      items: [
        { title: 'unit width', key: :unit_width },
        { title: 'pen width', key: :pen_width },
        { title: 'pen height', key: :pen_height }
      ]
    }, {
      title: 'Proportion',
      items: [
        { title: 'cap height', key: :cap_height },
        { title: 'bar height', key: :bar_height },
        { title: 'asc. height', key: :ascender_height },
        { title: 'desc. height', key: :descender_height },
        { title: 'glyph angle', key: :glyph_angle },
        { title: 'x-height', key: :x_height },
        { title: 'accents height', key: :accent_height },
        { title: 'depth of comma', key: :comma_depth }
      ]
    }, {
      title: 'Shape',
      items: [
        { title: 'horiz. increase', key: :horizontal_increase },
        { title: 'vert. increase', key: :vertical_increase },
        { title: 'contrast', key: :contrast },
        { title: 'superness', key: :superness },
        { title: 'pen angle', key: :pen_angle },
        { title: 'pen shape', key: :pen_shape, options:
          [{ value: '1', text: 'Circle' },
           { value: '2', text: 'Square' },
           { value: '3', text: 'Razor' }] },
        { title: 'slanting', key: :slant },
        { title: 'randomness', key: :craziness }
      ]
    }, {
      title: 'Optical corrections',
      items: [
        { title: 'aperture', key: :aperture },
        { title: 'corner', key: :corner },
        { title: 'overshoot', key: :overshoot },
        { title: 'taper', key: :taper }
      ]
    }]
  end

  def all
    i = 1

    # add properties needed for view
    all_with_each_item do |item|
      param = @font_parameters.send(item[:key])

      item[:default] = param.default
      item[:value] = param.value
      item[:range_from] = param.range && param.range[:from]
      item[:range_to] = param.range && param.range[:to]
      item[:hidden] = param.hidden
      item[:name] = item[:key]
      item[:tabindex] = i

      # special case for dropdowns
      if item[:options]
        item[:dropdown] = true
        selected = item[:options].select { |option| option[:value] == param.value }.first
        if selected
          selected[:selected] = true
        end
      end

      i = i + 1
    end
  end

  def all_with_each_item
    groups = default_parameters

    groups.each do |group|
      group[:items].each do |item|
        yield item
      end

      # remove non-mapped params
      group[:items].reject! { |item| !item[:default] || item[:hidden] }
    end

    # remove empty groups
    groups.reject! { |group| group[:items].empty? }

    groups
  end
end
