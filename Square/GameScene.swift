//
//  GameScene.swift
//  Square
//
//  Created by Lucia Reynoso on 9/17/18.
//  Copyright © 2018 Lucia Reynoso. All rights reserved.
//

import SpriteKit
import GameplayKit
import Accelerate
import simd

class GameScene: SKScene {
    // assets
    var centralBox: SKSpriteNode!
    let yOffset: CGFloat = 50
    let xOffset: CGFloat = 50
    struct HSBShifter {
        var value: CGFloat
        var phase: Bool
    }
    var rainbowHue = HSBShifter(value: 0.0, phase: true)
    var rainbowAlpha = HSBShifter(value: 1.0, phase: false)
    let ringNumber: Int = 3
    let squareSize = CGSize(width: 40, height: 40)
    var rings: [[SKSpriteNode]] = []
  
    override func didMove(to view: SKView) {
        // Called when the scene has been displayed
        let sceneCenter = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        centralBox = SKSpriteNode(texture: nil, color: .white, size: squareSize)
        centralBox.position.y = sceneCenter.y
        centralBox.position.x = sceneCenter.x
        addChild(centralBox)
        
        // initialize our boxes
        
        for index in 1...ringNumber {
            rings.append(boxMaker(ringLevel: index, boxSize: squareSize, center: sceneCenter))
        }
        for boxes in rings {
            for item in boxes {
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
    
    func boxMaker(ringLevel: Int, boxSize: CGSize, center: CGPoint) -> [SKSpriteNode] {
        var boxes: [SKSpriteNode] = []
        for row in -ringLevel...ringLevel {
            for col in -ringLevel...ringLevel {
                if !(abs(row) < ringLevel && abs(col) < ringLevel) {
                    let box = SKSpriteNode(texture: nil, color: .black, size: boxSize)
                    box.position.y = center.y + (yOffset * CGFloat(row))
                    box.position.x = center.x + (xOffset * CGFloat(col))
                    boxes.append(box)
                }
            }
        }
        return boxes
    }
    
    func shiftHSB(shift: HSBShifter, step: CGFloat) -> HSBShifter {
        var returnHSB: HSBShifter = shift
        if (returnHSB.value >= 1.0 && returnHSB.phase == true) || (returnHSB.value <= 0.0 && returnHSB.phase == false) {
            returnHSB.phase = !returnHSB.phase
        }
        else {
            switch returnHSB.phase {
            case true:
                returnHSB.value += step
            case false:
                returnHSB.value -= step
            }
        }
        return returnHSB
    }
    
    // this function gives each square the appropriate vector required to circle around the screen
    func orbit(_ planet: SKSpriteNode, radius: Int) {
        // shift coordinates to a system centered on the center of the screen
        let xSpan = self.size.width / 2
        let ySpan = self.size.height / 2
        let zero = CGPoint(x: xSpan, y: ySpan)
        let distance = CGFloat(50 * radius)
        let positionVector = simd_double2(x: Double(planet.position.x - zero.x), y: Double(planet.position.y - zero.y))
        let rotationAngle = Double.pi / 4
        let rotationMatrix = simd_double2x2([simd_double2(cos(rotationAngle), sin(rotationAngle)), simd_double2(-sin(rotationAngle), cos(rotationAngle))])
        let rotatedVector = positionVector * rotationMatrix
        
        var aim: CGPoint?
        var time: TimeInterval?
        
        if rotatedVector[0] >= 0 && rotatedVector[1] > 0 {
            // quadrant 1, going right; includes x = 0 from origin to positive y
            aim = CGPoint(x: zero.x + distance, y: zero.y + distance)
            time = TimeInterval(abs((aim?.x)! - planet.position.x) / 50)
        } else if rotatedVector[0] > 0 && rotatedVector[1] <= 0 {
            // quadrant 4, going down; includes y = 0 from origin to positive x
            aim = CGPoint(x: zero.x + distance, y: zero.y - distance)
            time = TimeInterval(abs((aim?.y)! - planet.position.y) / 50)
        } else if rotatedVector[0] <= 0 && rotatedVector[1] < 0 {
            // quadrant 3, going left; includes x = 0 from origin to negative y
            aim = CGPoint(x: zero.x - distance, y: zero.y - distance)
            time = TimeInterval(abs((aim?.x)! - planet.position.x) / 50)
        } else if rotatedVector[0] < 0 && rotatedVector[1] >= 0 {
            // quadrant 2, going up; includes y = 0 from origin to negative x
            aim = CGPoint(x: zero.x - distance, y: zero.y + distance)
            time = TimeInterval(abs((aim?.y)! - planet.position.y) / 50)
        }
        
        if let assignedAim = aim, let assignedTime = time {
            let slide = SKAction.move(to: assignedAim, duration: assignedTime)
            planet.run(slide)
        }
        
        /*
        if abs(planet.position.x - centerX) < goal {
            if planet.position.y > centerY {
                // then we must be on the top of our square orbit, going right
                let aim = CGPoint(x: centerX + goal, y: centerY + goal)
                let time = TimeInterval(abs(aim.x - planet.position.x) / 50)
                let slide = SKAction.move(to: aim, duration: time)
                planet.run(slide)
            } else if planet.position.y < centerY {
                // then we must be on the bottom of our square orbit, going left
                let aim = CGPoint(x: centerX - goal, y: centerY - goal)
                let time = TimeInterval(abs(aim.x - planet.position.x) / 50)
                let slide = SKAction.move(to: aim, duration: time)
                planet.run(slide)
            }
        } else if abs(planet.position.y - centerY) < goal {
            if planet.position.x > centerX {
                // then we must be on the right of our square orbit, going down
                let aim = CGPoint(x: centerX + goal, y: centerY - goal)
                let time = TimeInterval(abs(aim.y - planet.position.y) / 50)
                let slide = SKAction.move(to: aim, duration: time)
                planet.run(slide)
            } else if planet.position.x < centerX {
                // then we must be on the left of our square orbit, going up
                let aim = CGPoint(x: centerX - goal, y: centerY + goal)
                let time = TimeInterval(abs(aim.y - planet.position.y) / 50)
                let slide = SKAction.move(to: aim, duration: time)
                planet.run(slide)
            }
        }
        */
    }
}
