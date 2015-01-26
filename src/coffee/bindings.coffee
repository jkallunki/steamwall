$       = require 'jquery'
_       = require 'lodash'
ko      = require 'knockout'
loaded  = require 'imagesloaded'


ko.bindingHandlers.slideshow =
  init: (element, valueAccessor, allBindings, viewModel, bindingContext) ->
    imgEls = $(element).find '.img'
    pointer = 0
    updateImage = ->
      images = ko.unwrap valueAccessor()
      if images.length > 0
        # toggle images
        img = _.sample(images)

        $(imgEls[pointer])
          .css('background-image', 'url(' + img.src + ')')
          .removeClass('visible')
          .find('.author').text img.author

        pointer = (pointer + 1) % 2
        loaded imgEls[pointer], ->
          $(imgEls[pointer]).addClass 'visible'
          setTimeout updateImage, 5000
      else
        # wait for image data
        setTimeout updateImage, 1000
    updateImage()
