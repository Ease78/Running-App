//
//  MulticolorPolyline.swift
//  MoonRunner
//
//  Created by Ali on 8/22/17.
//  Copyright © 2017 Richard Critz. All rights reserved.
//

import MapKit

class MulticolorPolyline: MKPolyline {
  var color = UIColor.black
  
  //to differentiate polylines on the map by colors, depending on the speed/pace
  private func segmentColor(speed: Double, midSpeed: Double, slowestSpeed: Double, fastestSpeed: Double) -> UIColor{
    enum BaseColors{
      static let r_red: CGFloat = 20 / 255
      static let r_green: CGFloat = 20 / 255
      static let r_blue: CGFloat = 44 / 255
      
      static let y_red: CGFloat = 1
      static let y_green: CGFloat = 215 / 255
      static let y_blue: CGFloat = 0
      
      static let g_red: CGFloat = 0
      static let g_green: CGFloat = 146 / 255
      static let g_blue: CGFloat = 78 / 255
    }
    
    
    // slow: red, medium: yellow, fast: green
    let red, green, blue: CGFloat
    
    if speed < midSpeed {
    let ratio = CGFloat ((speed - slowestSpeed)/(midSpeed - slowestSpeed))
      red = BaseColors.r_red + ratio * (BaseColors.y_red - BaseColors.r_red)
      green = BaseColors.r_green + ratio * (BaseColors.y_green - BaseColors.r_green)
      blue = BaseColors.r_blue + ratio * (BaseColors.y_blue - BaseColors.r_blue)
    } else {
      let ratio = CGFloat((speed - midSpeed) / (fastestSpeed - midSpeed))
      red = BaseColors.y_red + ratio * (BaseColors.g_red - BaseColors.y_red)
      green = BaseColors.y_green + ratio * (BaseColors.g_green - BaseColors.y_green)
      blue = BaseColors.y_blue + ratio * (BaseColors.g_blue - BaseColors.y_blue)

    }
    return UIColor(red: red, green: green, blue: blue, alpha: 1)
  }
  
}
