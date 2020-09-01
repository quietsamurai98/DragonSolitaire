# coding: utf-8
# Copyright 2019 DragonRuby LLC
# MIT License
# attr_gtk.rb has been released under MIT (*only this file*).

# @private
module AttrGTK
  attr_accessor :args

  def keyboard
    args.inputs.keyboard
  end

  def grid
    args.grid
  end

  def state
    args.state
  end

  def inputs
    args.inputs
  end

  def outputs
    args.outputs
  end

  # @return [OpenStruct]
  def gtk
    args.gtk
  end

  def passes
    args.passes
  end

  def geometry
    args.geometry
  end
end
