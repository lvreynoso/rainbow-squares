//
//  GameScene.swift
//  Rainbow-Squares
//
//  Created by Lucia Reynoso on 9/17/18.
//  Copyright © 2018 Lucia Reynoso. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    // assets
    var centralBox: SKSpriteNode!
    struct HSBShifter {
        var value: CGFloat
        var phase: Bool
    }
    var rainbowHue = HSBShifter(value: 0.0, phase: true)
    var rainbowAlpha = HSBShifter(value: 1.0, phase: false)
    let ringNumber: Int = 3 //Int.random(in: 1...6)
    let squareSize = CGSize(width: 40, height: 40)
    var rings: [[SKSpriteNode]] = []
    var orbits: [[CGPoint]] = []
  
    override func didMove(to view: SKView) {
        // Called when the scene has been displayed
        let sceneCenter = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        centralBox = SKSpriteNode(texture: nil, color: .white, size: squareSize)
        centralBox.position = sceneCenter
        addChild(centralBox)
        
        // initialize our boxes
        
        for index in 1...ringNumber {
            rings.append(boxMaker(ringLevel: index, center: sceneCenter))
        }
        
        for index in 1...rings.count {
            // sort orbit points by angle
            orbits[index - 1].sort {
                if atan2(($0.x - sceneCenter.x), ($0.y - sceneCenter.y)) < atan2(($1.x - sceneCenter.x), ($1.y - sceneCenter.y)) {
                    return true
                } else {
                    return false
                }
            }
            for item in rings[index - 1] {
                addChild(item)
            }
        }
        
    }
    
  
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        var shiftHue = rainbowHue
        var currentLevel = 1
        for boxes in rings {
            for box in boxes {
                let currentHSB = UIColor(hue: shiftHue.value, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                box.color = currentHSB
                box.colorBlendFactor = 1.0
                if box.hasActions() != true {
                    orbit(box, radius: currentLevel)
                }
                shiftHue = shiftHSB(shift: shiftHue, step: 0.01)
            }
            currentLevel += 1
        }
 
        let centralHSB = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: rainbowAlpha.value)
        centralBox.color = centralHSB
        centralBox.colorBlendFactor = 1.0
        
        rainbowHue = shiftHSB(shift: rainbowHue, step: 0.002)
        rainbowAlpha = shiftHSB(shift: rainbowAlpha, step: 0.01)
        
    }
    
    func boxMaker(ringLevel: Int, center: CGPoint) -> [SKSpriteNode] {
        var boxes: [SKSpriteNode] = []
        var orbit: [CGPoint] = []
        for row in -ringLevel...ringLevel {
            for col in -ringLevel...ringLevel {
                if !(abs(row) < ringLevel && abs(col) < ringLevel) {
                    let box = SKSpriteNode(texture: nil, color: .black, size: squareSize)
                    box.position.y = center.y + ((squareSize.height * 1.25) * CGFloat(row))
                    box.position.x = center.x + ((squareSize.width * 1.25) * CGFloat(col))
                    boxes.append(box)
                    orbit.append(box.position)
                }
            }
        }
        orbits.append(orbit)
        return boxes
    }
    
    func shiftHSB(shift: HSBShifter, step: CGFloat) -> HSBShifter {
        var returnHSB: HSBShifter = shift
        if (returnHSB.value >= 1.0 && returnHSB.phase == true) || (returnHSB.value <= 0.0 && returnHSB.phase == false) {
            returnHSB.phase = !returnHSB.phase
        }
        switch returnHSB.phase {
        case true:
            returnHSB.value += step
        case false:
            returnHSB.value -= step
        }
        return returnHSB
    }
    
    // this function tells each square in each ring to travel to the next point recorded in orbits
    func orbit(_ planet: SKSpriteNode, radius: Int) {
        var nextPoint: CGPoint?
        for index in 1...orbits[radius - 1].count {
            if orbits[radius - 1][index - 1] == planet.position {
                if index == orbits[radius - 1].count {
                    nextPoint = orbits[radius - 1][0]
                } else {
                    nextPoint = orbits[radius - 1][index]
                }
            }
        }
        if let assignedPoint = nextPoint {
            let slide = SKAction.move(to: assignedPoint, duration: 1.0)
            planet.run(slide)
        }
    }
    
}
