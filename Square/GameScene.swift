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
    struct HSBShifter {
        var value: CGFloat
        var phase: Bool
    }
    var rainbowHue = HSBShifter(value: 0.0, phase: true)
    var rainbowAlpha = HSBShifter(value: 1.0, phase: false)
    let ringNumber: Int = 3
    let squareSize = CGSize(width: 40, height: 40)
    var rings: [[SKSpriteNode]] = []
    var orbits: [[CGPoint]] = []
  
    override func didMove(to view: SKView) {
        // Called when the scene has been displayed
        let sceneCenter = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        centralBox = SKSpriteNode(texture: nil, color: .white, size: squareSize)
        centralBox.position.y = sceneCenter.y
        centralBox.position.x = sceneCenter.x
        addChild(centralBox)
        
        // initialize our boxes
        
        for index in 1...ringNumber {
            rings.append(boxMaker(ringLevel: index, center: sceneCenter))
            orbits.append(createOrbits(ringLevel: index, center: sceneCenter))
        }
        for index in 1...rings.count {
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
        for row in -ringLevel...ringLevel {
            for col in -ringLevel...ringLevel {
                if !(abs(row) < ringLevel && abs(col) < ringLevel) {
                    let box = SKSpriteNode(texture: nil, color: .black, size: squareSize)
                    box.position.y = center.y + ((squareSize.height * 1.25) * CGFloat(row))
                    box.position.x = center.x + ((squareSize.width * 1.25) * CGFloat(col))
                    boxes.append(box)
                }
            }
        }
        return boxes
    }
    
    // TODO: improve this by simply collecting points from box creation and sort them clockwise
    func createOrbits(ringLevel: Int, center: CGPoint) -> [CGPoint] {
        var pointerPoint = CGPoint(x: 0, y: 0)
        var orbit: [CGPoint] = []
        let xStep: CGFloat = (squareSize.width * 1.25)
        let yStep: CGFloat = (squareSize.height * 1.25)
        pointerPoint = CGPoint(x: center.x - (xStep * CGFloat(ringLevel)), y: center.y - (yStep * CGFloat(ringLevel)))
        orbit.append(pointerPoint)
        for _ in 1...(2 * ringLevel) {
            pointerPoint.y += yStep
            orbit.append(pointerPoint)
        }
        for _ in 1...(2 * ringLevel) {
            pointerPoint.x += xStep
            orbit.append(pointerPoint)
        }
        for _ in 1...(2 * ringLevel) {
            pointerPoint.y += -yStep
            orbit.append(pointerPoint)
        }
        for _ in 1...(2 * ringLevel) {
            pointerPoint.x += -xStep
            orbit.append(pointerPoint)
        }
        orbit.removeLast()
        return orbit
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
    
    /*
    // this function gives each square the appropriate vector required to circle around the screen
    func orbitVector(_ planet: SKSpriteNode, radius: Int) {
        // shift coordinates to a system centered on the center of the screen
        let zero = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
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
        } else {
            print("fml")
        }
        
        if let assignedAim = aim, let assignedTime = time {
            let slide = SKAction.move(to: assignedAim, duration: assignedTime)
            print("Assigned square to move to coords (\(assignedAim.x), \(assignedAim.y)) over \(assignedTime) seconds")
            planet.run(slide)
        }
    }
    */
    
}
