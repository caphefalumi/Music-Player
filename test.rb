require 'rubygems'
require 'gosu'



class Board

end
module Piece
  NONE   = 0
  KING   = 1
  PAWN   = 2
  BISHOP = 3
  KNIGHT = 4
  ROOK   = 5
  QUEEN  = 6
  WHITE  = 8
  BLACK  = 16
end


class Chess < Gosu::Window
  def initialize
    super 640, 640
    self.caption = "Chess"

    @board = Board.new
  end
  def draw
    for file in 0..8
      for rank in 0..8
        isLightSquare = (file+rank)%2!=0
        squareColor = isLightSquare ? Gosu::Color.new(0xFFF1D9C0) : Gosu::Color.new(0xFFA97A65)
        Gosu.draw_rect(file*80, rank*80, 80, 80, squareColor)
      end
    end
  end
end
Chess.new.show