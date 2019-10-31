#!/usr/bin/env ruby

class String
  def default
    colorize self, "\e[39m"
  end

  def black
    colorize(self, "\e[30m")
  end

  def red
    colorize(self, "\e[31m")
  end

  def green
    colorize(self, "\e[32m")
  end

  def yellow
    colorize(self, "\e[33m")
  end

  def blue
    colorize(self, "\e[34m")
  end

  def magenta
    colorize(self, "\e[35m")
  end

  def cyan
    colorize self, "\e[36m"
  end

  def light_gray
    colorize(self, "\e[37m")
  end

  def dark_gray
    colorize(self, "\e[90m")
  end

  def light_red
    colorize(self, "\e[91m")
  end

  def light_green
    colorize(self, "\e[92m")
  end

  def light_yellow
    colorize(self, "\e[93m")
  end

  def light_blue
    colorize(self, "\e[94m")
  end

  def light_magenta
    colorize(self, "\e[95m")
  end

  def light_cyan
    colorize(self, "\e[96m")
  end

  def white
    colorize(self, "\e[97m")
  end

  def colorize(text, color_code)
    "#{color_code}#{text}\e[0m"
  end

  def bold
    "\e[1m#{self}\e[0m"
  end

  def underlined
    "\e[4m#{self}\e[0m"
  end
end
